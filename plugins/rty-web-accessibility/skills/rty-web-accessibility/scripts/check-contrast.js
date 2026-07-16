function getLuminance(r, g, b) {
  const a = [r, g, b].map((v) => {
    v /= 255;
    return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  });
  return a[0] * 0.2126 + a[1] * 0.7152 + a[2] * 0.0722;
}

function getContrastRatio(color1, color2) {
  // color1 and color2 are arrays of [r, g, b]
  const lum1 = getLuminance(color1[0], color1[1], color1[2]);
  const lum2 = getLuminance(color2[0], color2[1], color2[2]);
  const brightest = Math.max(lum1, lum2);
  const darkest = Math.min(lum1, lum2);
  return (brightest + 0.05) / (darkest + 0.05);
}

function hexToRgb(hex) {
  if (!hex || typeof hex !== 'string') return null;
  // Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
  const shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
  hex = hex.replace(shorthandRegex, (m, r, g, b) => {
    return r + r + g + g + b + b;
  });

  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})?$/i.exec(hex);
  if (!result) return null;
  const r = parseInt(result[1], 16);
  const g = parseInt(result[2], 16);
  const b = parseInt(result[3], 16);
  if (result[4]) {
    // Composite against a white background: result = alpha * fg + (1 - alpha) * 255
    const alpha = parseInt(result[4], 16) / 255;
    return [
      Math.round(alpha * r + (1 - alpha) * 255),
      Math.round(alpha * g + (1 - alpha) * 255),
      Math.round(alpha * b + (1 - alpha) * 255),
    ];
  }
  return [r, g, b];
}

// Ensure the script is called with correct arguments
if (process.argv.length !== 4) {
  console.error("Usage: node check-contrast.js <hex-color-1> <hex-color-2>");
  process.exit(1);
}

const color1Hex = process.argv[2];
const color2Hex = process.argv[3];

const color1Rgb = hexToRgb(color1Hex);
const color2Rgb = hexToRgb(color2Hex);

if (!color1Rgb || !color2Rgb) {
  console.error("Invalid hex color format.");
  process.exit(1);
}

const contrast = getContrastRatio(color1Rgb, color2Rgb);
const flooredContrast = Math.floor(contrast * 100) / 100;
console.log(`Contrast Ratio: ${flooredContrast.toFixed(2)}`);
console.log(`AA Normal Text (>= 4.5): ${flooredContrast >= 4.5 ? 'PASS' : 'FAIL'}`);
console.log(`AA Large Text (>= 3.0): ${flooredContrast >= 3.0 ? 'PASS' : 'FAIL'}`);
