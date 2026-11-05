#!/usr/bin/env python3
# Rebuilds Lock n Key Wallet/Resources/Acknowledgements.txt from the license files of the Swift
# packages Xcode has checked out. Run after adding, removing or updating a package (build once
# first so the checkouts exist), then review the diff.
#
#   python3 scripts/make_acknowledgements.py
#
# Only packages linked into the app or LNK AutoFill belong here. GoogleAppMeasurement and
# google-ads-on-device-conversion are resolved by firebase-ios-sdk but not linked.
import glob, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT  = os.path.join(ROOT, "Lock n Key Wallet", "Resources", "Acknowledgements.txt")
HERE = os.path.dirname(os.path.abspath(__file__))

matches = sorted(glob.glob(os.path.expanduser(
    "~/Library/Developer/Xcode/DerivedData/Lock_n_Key_Wallet-*/SourcePackages/checkouts")), key=os.path.getmtime)
if not matches:
    sys.exit("No package checkouts found. Build the project in Xcode first.")
CHECKOUTS = matches[-1]

# (display name, directory, license file). BoringSSL ships inside grpc-binary without its license,
# so a copy for the version gRPC 1.69 builds against is kept in scripts/licenses.
PACKAGES = [
    ("CreditCardScanner",             os.path.join(CHECKOUTS, "credit-card-scanner"),         "LICENSE.md"),
    ("Reg",                           os.path.join(CHECKOUTS, "Reg"),                         "LICENSE"),
    ("Sukar",                         os.path.join(CHECKOUTS, "Sukar"),                       "LICENSE.md"),
    ("Firebase iOS SDK",              os.path.join(CHECKOUTS, "firebase-ios-sdk"),            "LICENSE"),
    ("App Check",                     os.path.join(CHECKOUTS, "app-check"),                   "LICENSE"),
    ("GoogleDataTransport",           os.path.join(CHECKOUTS, "GoogleDataTransport"),         "LICENSE"),
    ("GoogleUtilities",               os.path.join(CHECKOUTS, "GoogleUtilities"),             "LICENSE"),
    ("GTM Session Fetcher",           os.path.join(CHECKOUTS, "gtm-session-fetcher"),         "LICENSE"),
    ("Interop for Google SDKs",       os.path.join(CHECKOUTS, "interop-ios-for-google-sdks"), "LICENSE"),
    ("Promises",                      os.path.join(CHECKOUTS, "promises"),                    "LICENSE"),
    ("Abseil",                        os.path.join(CHECKOUTS, "abseil-cpp-binary"),           "LICENSE"),
    ("gRPC",                          os.path.join(CHECKOUTS, "grpc-binary"),                 "LICENSE"),
    ("BoringSSL (bundled with gRPC)", os.path.join(HERE, "licenses"),                         "boringssl-0.20241024.0.txt"),
    ("LevelDB",                       os.path.join(CHECKOUTS, "leveldb"),                     "LICENSE"),
    ("nanopb",                        os.path.join(CHECKOUTS, "nanopb"),                      "LICENSE.txt"),
    ("SwiftProtobuf",                 os.path.join(CHECKOUTS, "swift-protobuf"),              "LICENSE.txt"),
]

parts = ["LNK Wallet uses the following open-source software.\n"]
for name, directory, filename in PACKAGES:
    with open(os.path.join(directory, filename), encoding="utf-8") as f:
        text = f.read().strip()
    rule = "=" * 40
    parts.append(f"\n{rule}\n{name}\n{rule}\n\n{text}\n")

with open(OUT, "w", encoding="utf-8") as f:
    f.write("".join(parts))
print(f"Wrote {OUT}")
