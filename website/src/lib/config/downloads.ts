export interface SplitPackageInfo {
  abi: "arm64-v8a" | "armeabi-v7a" | "x86_64" | "universal";
  name: string;
  tagline: string;
  architecture: string;
  description: string;
  recommended: boolean;
  filename: string;
  downloadUrl: string;
  checksumUrl: string;
  sizeFormatted: string;
  sizeBytes: number;
  sha256: string;
  minAndroid: string;
}

export const APP_RELEASE_VERSION = "v1.3.0";
export const APP_RELEASE_BUILD = "1.3.0+3";
export const APP_SCHEMA_VERSION = 1;

export const splitReleasePackages: SplitPackageInfo[] = [
  {
    abi: "arm64-v8a",
    name: "ARM64-v8a",
    tagline: "Recommended for 95%+ of modern smartphones",
    architecture: "64-bit ARM (aarch64)",
    description: "Designed for modern Android smartphones including Samsung Galaxy S/Z/A series, Google Pixel, OnePlus, Xiaomi, and Nothing Phone.",
    recommended: true,
    filename: "FitHost-v1.3.0-arm64-v8a.apk",
    downloadUrl: "https://github.com/xtenfit/fit-host/releases/download/v1.3.0/FitHost-v1.3.0-arm64-v8a.apk",
    checksumUrl: "https://github.com/xtenfit/fit-host/releases/download/v1.3.0/FitHost-v1.3.0-arm64-v8a.apk.sha256",
    sizeFormatted: "44.5 MB",
    sizeBytes: 44514274,
    sha256: "0f7443a47258a34e5e92fe783250aea4417300872f452a38d01632123c07b8ce",
    minAndroid: "Android 8.0+ (Oreo, API 26)",
  },
  {
    abi: "armeabi-v7a",
    name: "ARMeabi-v7a",
    tagline: "For legacy 32-bit Android devices",
    architecture: "32-bit ARM (armv7)",
    description: "Built for older Android smartphones, budget entry-level hardware, and legacy 32-bit processor platforms.",
    recommended: false,
    filename: "FitHost-v1.3.0-armeabi-v7a.apk",
    downloadUrl: "https://github.com/xtenfit/fit-host/releases/download/v1.3.0/FitHost-v1.3.0-armeabi-v7a.apk",
    checksumUrl: "https://github.com/xtenfit/fit-host/releases/download/v1.3.0/FitHost-v1.3.0-armeabi-v7a.apk.sha256",
    sizeFormatted: "41.4 MB",
    sizeBytes: 41367124,
    sha256: "ca631b8ac51167da9869c4096a1aa8f22f964d6be1e797b660beb10bb0fd63fb",
    minAndroid: "Android 8.0+ (Oreo, API 26)",
  },
  {
    abi: "x86_64",
    name: "x86_64",
    tagline: "For Emulators, Android x86 PCs & ChromeOS",
    architecture: "64-bit Intel / AMD",
    description: "Optimized for Android Studio virtual devices (AVD), Genymotion, Chromebooks with Android container, and x86 hardware.",
    recommended: false,
    filename: "FitHost-v1.3.0-x86_64.apk",
    downloadUrl: "https://github.com/xtenfit/fit-host/releases/download/v1.3.0/FitHost-v1.3.0-x86_64.apk",
    checksumUrl: "https://github.com/xtenfit/fit-host/releases/download/v1.3.0/FitHost-v1.3.0-x86_64.apk.sha256",
    sizeFormatted: "47.5 MB",
    sizeBytes: 47496151,
    sha256: "cddf910b9cc8c9e3fc04c2379e8ba8eecb301b41d6c185ddf8fa0de1b343d34f",
    minAndroid: "Android 8.0+ (Oreo, API 26)",
  },
  {
    abi: "universal",
    name: "Universal Fat APK",
    tagline: "Complete bundle with all native ABIs",
    architecture: "Multi-Architecture (ARM64 + ARMv7 + x86_64)",
    description: "Contains compiled native libraries for every Android architecture in a single package. Guaranteed to run on any compatible device.",
    recommended: false,
    filename: "FitHost-Android-v1.3.0.apk",
    downloadUrl: "https://github.com/xtenfit/fit-host/releases/download/v1.3.0/FitHost-Android-v1.3.0.apk",
    checksumUrl: "https://github.com/xtenfit/fit-host/releases/download/v1.3.0/FitHost-Android-v1.3.0.apk.sha256",
    sizeFormatted: "107.4 MB",
    sizeBytes: 112673151,
    sha256: "4f41b7b499dc5c32307bbeb02d2e8be72bc105f49ed56bea3c8b905078a8639c",
    minAndroid: "Android 8.0+ (Oreo, API 26)",
  },
];
