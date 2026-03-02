#!/usr/bin/env node
/**
 * generate-image.js
 *
 * Generate app icons, illustrations, and in-app assets via Fal.ai.
 * Model: fal-ai/nano-banana-2
 *
 * Usage:
 *   node .agents/tools/generate-image.js \
 *     --prompt "minimal flat illustration of a brain, dark bg, violet accent" \
 *     --output path/to/output.png \
 *     --size 1024x1024
 *
 * Env: FAL_API_KEY=your_key (or set in .env)
 */

const fs = require('fs')
const path = require('path')
const https = require('https')

// Load .env if present
try {
  const env = fs.readFileSync(path.join(__dirname, '../../backend/.env'), 'utf8')
  env.split('\n').forEach(line => {
    const [key, ...val] = line.split('=')
    if (key && val.length) process.env[key.trim()] = val.join('=').trim()
  })
} catch {}

const args = process.argv.slice(2)
const get = (flag) => {
  const i = args.indexOf(flag)
  return i !== -1 ? args[i + 1] : null
}

const prompt  = get('--prompt')
const output  = get('--output') || `generated-${Date.now()}.png`
const size    = get('--size') || '1024x1024'
const apiKey  = process.env.FAL_API_KEY

if (!prompt) {
  console.error('Error: --prompt is required')
  console.error('Usage: node generate-image.js --prompt "..." --output path.png')
  process.exit(1)
}

if (!apiKey) {
  console.error('Error: FAL_API_KEY not set')
  process.exit(1)
}

const [width, height] = size.split('x').map(Number)

async function generate() {
  console.log(`🎨 Generating: "${prompt}"`)
  console.log(`   Size: ${size}, Output: ${output}`)

  const body = JSON.stringify({
    prompt,
    image_size: { width, height },
    num_inference_steps: 28,
    guidance_scale: 3.5,
    num_images: 1,
    enable_safety_checker: true,
  })

  const response = await fetch('https://fal.run/fal-ai/nano-banana-2', {
    method: 'POST',
    headers: {
      'Authorization': `Key ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body,
  })

  if (!response.ok) {
    const err = await response.text()
    console.error(`Fal.ai error ${response.status}: ${err}`)
    process.exit(1)
  }

  const data = await response.json()
  const imageUrl = data.images?.[0]?.url

  if (!imageUrl) {
    console.error('No image URL in response:', JSON.stringify(data))
    process.exit(1)
  }

  // Download image
  const dir = path.dirname(output)
  if (dir && !fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true })

  const imgResponse = await fetch(imageUrl)
  const buffer = Buffer.from(await imgResponse.arrayBuffer())
  fs.writeFileSync(output, buffer)

  console.log(`✅ Saved to: ${output}`)
  console.log(`   Seed: ${data.seed ?? 'n/a'}`)
}

generate().catch(err => {
  console.error('Unexpected error:', err)
  process.exit(1)
})
