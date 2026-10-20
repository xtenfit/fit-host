const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const SRC_DIR = path.resolve(__dirname, '../assets/images');
const OUT_DIR = path.resolve(__dirname, '../assets/optimized');
const IN_PLACE_OPTIMIZE = true;

// Unreferenced assets to exclude / clean up
const UNREFERENCED_FILES = [
  'branding/wordmark.jpg',
  'categories/nutrition.png',
  'categories/recovery.png',
  'workouts/strength.jpg',
  'workouts/strength_hero.jpg',
  'workouts/strength_hero.png',
  'anatomy/anatomy_back.png',
  'anatomy/anatomy_biceps.png',
  'anatomy/anatomy_chest.png',
  'anatomy/anatomy_core.png',
  'anatomy/anatomy_legs.png',
  'anatomy/anatomy_shoulders.png',
  'workouts/bodyweight.png',
  'workouts/cardio.png',
  'workouts/cycling.png',
  'workouts/hiit.png',
  'workouts/meditation.png',
  'workouts/mobility.png',
  'workouts/running.png',
  'workouts/stretching.png',
  'workouts/yoga.png',
];

async function getAllFiles(dir, fileList = []) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      await getAllFiles(fullPath, fileList);
    } else if (/\.(png|jpe?g)$/i.test(entry.name)) {
      fileList.push(fullPath);
    }
  }
  return fileList;
}

async function run() {
  console.log('🚀 Starting Unlimited Lossless / Near-Lossless Asset Compression Pipeline...');
  console.log(`Source Directory: ${SRC_DIR}`);
  console.log(`Optimized Output Directory: ${OUT_DIR}\n`);

  if (!fs.existsSync(OUT_DIR)) {
    fs.mkdirSync(OUT_DIR, { recursive: true });
  }

  // Remove unreferenced files from SRC_DIR and OUT_DIR if present
  for (const unref of UNREFERENCED_FILES) {
    const srcP = path.join(SRC_DIR, unref);
    if (fs.existsSync(srcP)) {
      fs.unlinkSync(srcP);
      console.log(`🗑️ Removed unreferenced source asset: ${unref}`);
    }
    const outPng = path.join(OUT_DIR, unref);
    if (fs.existsSync(outPng)) {
      fs.unlinkSync(outPng);
    }
    const outWebp = outPng.replace(/\.(png|jpe?g)$/i, '.webp');
    if (fs.existsSync(outWebp)) {
      fs.unlinkSync(outWebp);
    }
  }

  const files = await getAllFiles(SRC_DIR);
  console.log(`\nFound ${files.length} active images to compress.\n`);

  let totalOriginalBytes = 0;
  let totalOptimizedBytes = 0;

  for (const filePath of files) {
    const relPath = path.relative(SRC_DIR, filePath);
    const outPngPath = path.join(OUT_DIR, relPath);
    const outWebpPath = outPngPath.replace(/\.(png|jpe?g)$/i, '.webp');

    const outDirname = path.dirname(outPngPath);
    if (!fs.existsSync(outDirname)) {
      fs.mkdirSync(outDirname, { recursive: true });
    }

    const origStats = fs.statSync(filePath);
    totalOriginalBytes += origStats.size;

    const isIconOrLogo = relPath.includes('branding') || relPath.includes('avatars') || relPath.includes('icon');

    // 1. Lossless/near-lossless PNG optimization using libimagequant / palette
    // In-place optimization: updates the referenced asset in assets/images
    let sharpInstance = sharp(filePath);
    if (!isIconOrLogo) {
      sharpInstance = sharpInstance.resize({ width: 1024, withoutEnlargement: true });
    }

    const pngBuffer = await sharpInstance
      .clone()
      .png({
        palette: true,
        quality: isIconOrLogo ? 92 : 80,
        compressionLevel: 8,
        effort: 4,
      })
      .toBuffer();

    if (IN_PLACE_OPTIMIZE && pngBuffer.length < origStats.size) {
      fs.writeFileSync(filePath, pngBuffer);
    }

    // 2. Visually lossless WebP optimization (q=85) saved into assets/optimized
    const webpBuffer = await sharp(filePath)
      .resize(isIconOrLogo ? {} : { width: 1024, withoutEnlargement: true })
      .webp({
        quality: 85,
        effort: 4,
      })
      .toBuffer();

    fs.writeFileSync(outWebpPath, webpBuffer);
    if (isIconOrLogo) {
      fs.writeFileSync(outPngPath, pngBuffer);
    }

    totalOptimizedBytes += webpBuffer.length;

    const reduction = ((1 - webpBuffer.length / origStats.size) * 100).toFixed(1);
    console.log(
      `✓ [${reduction}% smaller] ${relPath} : ${(origStats.size / 1024).toFixed(0)}KB -> ${(webpBuffer.length / 1024).toFixed(0)}KB (WebP)`
    );
  }

  const totalOrigMB = (totalOriginalBytes / (1024 * 1024)).toFixed(2);
  const totalOptMB = (totalOptimizedBytes / (1024 * 1024)).toFixed(2);
  const totalReduction = ((1 - totalOptimizedBytes / totalOriginalBytes) * 100).toFixed(1);

  console.log('\n======================================================');
  console.log(`🏁 COMPRESSION COMPLETE!`);
  console.log(`Original Assets Size:  ${totalOrigMB} MB`);
  console.log(`Optimized Assets Size: ${totalOptMB} MB`);
  console.log(`Total Reduction:       ${totalReduction}%`);
  console.log('======================================================\n');
}

run().catch((err) => {
  console.error('Error running compression pipeline:', err);
  process.exit(1);
});
