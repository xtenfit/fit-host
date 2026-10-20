import { NextRequest, NextResponse } from "next/server";
import { revalidateTag, revalidatePath } from "next/cache";
import { releasesConfig } from "@/lib/config/releases";

export async function POST(request: NextRequest) {
  return handleRevalidation(request);
}

export async function GET(request: NextRequest) {
  return handleRevalidation(request);
}

async function handleRevalidation(request: NextRequest) {
  const expectedSecret = process.env.REVALIDATION_SECRET || releasesConfig.revalidation.secret;

  if (!expectedSecret) {
    return NextResponse.json(
      {
        error: "Server configuration error: REVALIDATION_SECRET is not configured on the server.",
      },
      { status: 500 }
    );
  }

  // 1. Check header 'x-revalidate-secret'
  const headerSecret = request.headers.get("x-revalidate-secret");

  // 2. Check Authorization Bearer header
  const authHeader = request.headers.get("authorization");
  const bearerSecret = authHeader?.startsWith("Bearer ") ? authHeader.substring(7) : null;

  // 3. Check query param '?secret=...'
  const { searchParams } = new URL(request.url);
  const querySecret = searchParams.get("secret");

  const providedSecret = headerSecret || bearerSecret || querySecret;

  if (!providedSecret || providedSecret !== expectedSecret) {
    return NextResponse.json(
      {
        error: "Unauthorized: Invalid or missing revalidation secret token.",
      },
      { status: 401 }
    );
  }

  try {
    // Invalidate the tag-based release cache immediately in Next.js 16
    revalidateTag(releasesConfig.revalidation.tag, { expire: 0 });

    // Revalidate public routes that display release metadata
    revalidatePath("/");
    revalidatePath("/download");
    revalidatePath("/updates");

    return NextResponse.json({
      revalidated: true,
      timestamp: new Date().toISOString(),
      tag: releasesConfig.revalidation.tag,
      paths: ["/", "/download", "/updates"],
      message: "Fit Host mobile release cache successfully purged and revalidated.",
    });
  } catch (error) {
    console.error("[Revalidate Releases] Error executing cache revalidation:", error);
    return NextResponse.json(
      {
        error: "Internal error occurred during Next.js cache revalidation.",
      },
      { status: 500 }
    );
  }
}
