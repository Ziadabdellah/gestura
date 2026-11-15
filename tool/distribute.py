import argparse
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent
APP = ROOT / "apps" / "gestura"
TARGETS = {
    "staging": ("gestura-dev-9ca1a", "1:755238171778:android:e62c4b0f8f9620c556f09b", "lib/main_staging.dart"),
    "prod": ("gestura-prod", "1:51915729825:android:b5149f9b1d5579ab42f9e0", "lib/main_prod.dart"),
}


def run(command, cwd):
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=cwd, check=True)


def main():
    parser = argparse.ArgumentParser(description="Build an Android release APK and send it to testers through Firebase App Distribution.")
    parser.add_argument("flavor", choices=sorted(TARGETS))
    parser.add_argument("--build-number", type=int, required=True)
    parser.add_argument("--notes", default="")
    parser.add_argument("--groups", default="testers")
    args = parser.parse_args()

    project, app_id, entry = TARGETS[args.flavor]
    run(
        [
            "fvm", "flutter", "build", "apk",
            "--flavor", args.flavor,
            "-t", entry,
            "--release",
            "--obfuscate",
            f"--split-debug-info=build/symbols/{args.flavor}",
            f"--build-number={args.build_number}",
        ],
        APP,
    )
    apk = APP / "build" / "app" / "outputs" / "flutter-apk" / f"app-{args.flavor}-release.apk"
    command = [
        "firebase", "appdistribution:distribute", str(apk),
        "--app", app_id,
        "--project", project,
        "--release-notes", args.notes or f"Gestura {args.flavor} build {args.build_number}",
    ]
    if args.groups:
        command += ["--groups", args.groups]
    run(command, ROOT)


if __name__ == "__main__":
    main()
