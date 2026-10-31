import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

/**
 * Exercise Media Manifest API Route
 * Delivers versioned, machine-readable media metadata with CDN and fallback endpoints,
 * file sizes, SHA-256 checksums, and licensing provenance.
 */
export async function GET() {
  try {
    const manifestPath = path.join(process.cwd(), 'public', 'exercise_media_manifest.json');
    
    if (!fs.existsSync(manifestPath)) {
      return NextResponse.json(
        { error: 'Exercise media manifest not found on server' },
        { status: 404 }
      );
    }

    const fileContent = fs.readFileSync(manifestPath, 'utf-8');
    const manifestData = JSON.parse(fileContent);

    return NextResponse.json(manifestData, {
      status: 200,
      headers: {
        'Cache-Control': 'public, max-age=3600, s-maxage=86400, stale-while-revalidate=86400',
        'Content-Type': 'application/json',
      },
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to read exercise media manifest', details: String(error) },
      { status: 500 }
    );
  }
}
