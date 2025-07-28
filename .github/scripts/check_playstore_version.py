import os
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build

PACKAGE_NAME = "com.ByteMechanics.matscape"

def get_latest_version_code(service, package_name):
    edits = service.edits()
    edit_request = edits.insert(body={}, packageName=package_name)
    result = edit_request.execute()
    edit_id = result["id"]

    tracks = edits.tracks().list(
        packageName=package_name, editId=edit_id
    ).execute()

    version_codes = []
    for track in tracks.get("tracks", []):
        for release in track.get("releases", []):
            version_codes.extend(release.get("versionCodes", []))

    if not version_codes:
        print("No versionCodes found in Play Store.")
        return None

    return max(map(int, version_codes))

def main():
    # Try multiple possible paths for the credentials file
    possible_paths = [
        os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"),
        "app/play_services.json",
        os.path.join(os.path.dirname(__file__), "app", "play_services.json"),
        "service_account_key.json"
    ]

    creds_path = None
    for path in possible_paths:
        if path and os.path.exists(path):
            creds_path = path
            break

    if not creds_path:
        print("❌ Missing credentials file. Please ensure one of these files exists:")
        print("   - app/play_services.json")
        print("   - service_account_key.json")
        print("   - Or set GOOGLE_APPLICATION_CREDENTIALS environment variable")
        sys.exit(1)

    credentials = service_account.Credentials.from_service_account_file(
        creds_path,
        scopes=["https://www.googleapis.com/auth/androidpublisher"],
    )
    service = build("androidpublisher", "v3", credentials=credentials)

    version_code = get_latest_version_code(service, PACKAGE_NAME)
    if version_code is not None:
        print(f"Latest Play Store versionCode: {version_code}")
        print(f"::set-output name=versionCode::{version_code}")
    else:
        print("::set-output name=versionCode::0")  # Assume 0 if none found

if __name__ == "__main__":
    main()
