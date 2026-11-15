import argparse
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
APP = ROOT / "apps" / "gestura"
SYMBOLS = APP / "build" / "symbols" / "android"
PROD_ANDROID_APP = "1:51915729825:android:b5149f9b1d5579ab42f9e0"


def run(command, cwd):
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=cwd, check=True)


def main():
    parser = argparse.ArgumentParser(description="Build the signed, obfuscated prod app bundle and upload its symbols.")
    parser.add_argument("--build-number", type=int, required=True)
    parser.add_argument("--build-name")
    parser.add_argument("--skip-symbols", action="store_true")
    args = parser.parse_args()

    if not (APP / "android" / "key.properties").exists():
        sys.exit("android/key.properties is missing: the bundle would not be signed with the upload key.")

    build = [
        "fvm", "flutter", "build", "appbundle",
        "--flavor", "prod",
        "-t", "lib/main_prod.dart",
        "--release",
        "--obfuscate",
        f"--split-debug-info={SYMBOLS}",
        f"--build-number={args.build_number}",
    ]
    if args.build_name:
        build.append(f"--build-name={args.build_name}")
    run(build, APP)

    if not args.skip_symbols:
        run(
            [
                "firebase", "crashlytics:symbols:upload",
                f"--app={PROD_ANDROID_APP}",
                "--project", "gestura-prod",
                str(SYMBOLS),
            ],
            ROOT,
        )

    print(APP / "build" / "app" / "outputs" / "bundle" / "prodRelease" / "app-prod-release.aab")


if __name__ == "__main__":
    main()
