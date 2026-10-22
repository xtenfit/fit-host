import { NextResponse } from "next/server";
import { getLatestMobileRelease } from "@/lib/github/releases";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const release = await getLatestMobileRelease();
    return NextResponse.json(
      {
        success: true,
        release,
        timestamp: new Date().toISOString(),
      },
      {
        status: 200,
        headers: {
          "Cache-Control": "public, s-maxage=60, stale-while-revalidate=300",
        },
      }
    );
  } catch (error) {
    console.error("[API Releases] Error retrieving latest release:", error);
    return NextResponse.json(
      {
        success: false,
        error: "Failed to retrieve latest mobile release record.",
      },
      { status: 500 }
    );
  }
}
