#!/usr/bin/env python3
"""Resolve the latest Progressive PR Docker image for fluxor-staging rollouts."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from typing import Any
from urllib.parse import urlparse


DEFAULT_CHECK_NAME = "Build and push Docker image"
DEFAULT_PROJECT_ID = "analog-stage-198105"
SHORT_SHA_LEN = 7


class ResolveError(RuntimeError):
    """Raised when the PR image cannot be resolved."""


@dataclass
class BuildCheck:
    name: str
    status: str
    conclusion: str | None
    details_url: str


def run_gh(args: list[str]) -> str:
    result = subprocess.run(
        ["gh", *args],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        stderr = result.stderr.strip() or result.stdout.strip() or "gh command failed"
        raise ResolveError(stderr)
    return result.stdout


def load_pr(repo: str, pr_number: int) -> dict[str, Any]:
    output = run_gh(
        [
            "pr",
            "view",
            str(pr_number),
            "--repo",
            repo,
            "--json",
            "number,headRefName,headRefOid,statusCheckRollup",
        ]
    )
    return json.loads(output)


def find_build_check(pr_data: dict[str, Any], check_name: str) -> BuildCheck:
    for item in pr_data.get("statusCheckRollup", []):
        if item.get("__typename") != "CheckRun":
            continue
        if item.get("name") != check_name:
            continue
        details_url = item.get("detailsUrl") or ""
        if not details_url:
            raise ResolveError(f"check '{check_name}' is missing a details URL")
        return BuildCheck(
            name=item["name"],
            status=item.get("status", ""),
            conclusion=item.get("conclusion"),
            details_url=details_url,
        )
    raise ResolveError(f"could not find check named '{check_name}' on the PR")


def parse_job_ids(details_url: str) -> tuple[int, int]:
    parsed = urlparse(details_url)
    match = re.search(r"/actions/runs/(\d+)/job/(\d+)", parsed.path)
    if not match:
        raise ResolveError(f"could not parse run/job ids from {details_url}")
    return int(match.group(1)), int(match.group(2))


def load_job_logs(repo: str, job_id: int) -> str:
    return run_gh(["api", f"repos/{repo}/actions/jobs/{job_id}/logs"])


def extract_image(logs: str, project_id: str) -> str:
    masked_match = re.search(r'"image\.name":\s*"gcr\.io/\*\*\*/progressive/([^"]+)"', logs)
    if masked_match:
        return f"gcr.io/{project_id}/progressive/{masked_match.group(1)}"

    full_match = re.search(r'"image\.name":\s*"(gcr\.io/[^"]+/progressive/[^"]+)"', logs)
    if full_match:
        return full_match.group(1)

    raise ResolveError("could not find image.name in the build job logs")


def validate_image_against_pr(image: str, head_ref_name: str, head_ref_oid: str) -> None:
    _, separator, tag = image.rpartition(":")
    if not separator:
        raise ResolveError(f"resolved image is missing a tag: {image}")

    path_prefix = "/progressive/"
    if path_prefix not in image:
        raise ResolveError(f"resolved image is not a progressive image: {image}")

    image_branch = image.split(path_prefix, 1)[1].rsplit(":", 1)[0]
    if image_branch != head_ref_name:
        raise ResolveError(
            "resolved image branch does not match the current PR head: "
            f"expected {head_ref_name}, got {image_branch}"
        )

    short_sha = head_ref_oid[:SHORT_SHA_LEN]
    if not tag.startswith(short_sha):
        raise ResolveError(
            "resolved image tag does not match the current PR head SHA: "
            f"expected prefix {short_sha}, got {tag}"
        )


def wait_for_check(
    repo: str,
    pr_number: int,
    check_name: str,
    should_wait: bool,
    timeout_seconds: int,
    poll_seconds: int,
) -> tuple[dict[str, Any], BuildCheck]:
    deadline = time.monotonic() + timeout_seconds

    while True:
        pr_data = load_pr(repo, pr_number)
        build_check = find_build_check(pr_data, check_name)

        if build_check.status == "COMPLETED":
            return pr_data, build_check

        if not should_wait:
            raise ResolveError(
                f"check '{check_name}' is still {build_check.status.lower()} for PR #{pr_number}"
            )

        if time.monotonic() >= deadline:
            raise ResolveError(
                f"timed out waiting for '{check_name}' on PR #{pr_number} after {timeout_seconds}s"
            )

        time.sleep(poll_seconds)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve the current Docker image for a Progressive pull request."
    )
    parser.add_argument("--repo", default="LuxorLabs/progressive", help="GitHub repo in owner/name form")
    parser.add_argument("--pr", type=int, required=True, help="Pull request number")
    parser.add_argument(
        "--check-name",
        default=DEFAULT_CHECK_NAME,
        help="Name of the GitHub check that builds the image",
    )
    parser.add_argument(
        "--project-id",
        default=DEFAULT_PROJECT_ID,
        help="GCR project id used to reconstruct masked image names",
    )
    parser.add_argument("--wait", action="store_true", help="Poll until the build check completes")
    parser.add_argument(
        "--timeout-seconds",
        type=int,
        default=1800,
        help="Maximum time to wait when --wait is enabled",
    )
    parser.add_argument(
        "--poll-seconds",
        type=int,
        default=15,
        help="Polling interval when --wait is enabled",
    )
    parser.add_argument(
        "--image-only",
        action="store_true",
        help="Print only the image string instead of JSON",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    try:
        pr_data, build_check = wait_for_check(
            repo=args.repo,
            pr_number=args.pr,
            check_name=args.check_name,
            should_wait=args.wait,
            timeout_seconds=args.timeout_seconds,
            poll_seconds=args.poll_seconds,
        )
    except ResolveError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    if build_check.conclusion != "SUCCESS":
        print(
            f"check '{build_check.name}' finished with conclusion={build_check.conclusion} for PR #{args.pr}",
            file=sys.stderr,
        )
        return 2

    try:
        run_id, job_id = parse_job_ids(build_check.details_url)
        logs = load_job_logs(args.repo, job_id)
        image = extract_image(logs, args.project_id)
        validate_image_against_pr(image, pr_data["headRefName"], pr_data["headRefOid"])
    except ResolveError as exc:
        print(str(exc), file=sys.stderr)
        return 3

    if args.image_only:
        print(image)
        return 0

    payload = {
        "pr": pr_data["number"],
        "head_ref_name": pr_data["headRefName"],
        "head_ref_oid": pr_data["headRefOid"],
        "check_name": build_check.name,
        "check_status": build_check.status,
        "check_conclusion": build_check.conclusion,
        "run_id": run_id,
        "job_id": job_id,
        "image": image,
    }
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
