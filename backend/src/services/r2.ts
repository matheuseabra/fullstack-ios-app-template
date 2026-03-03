import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'
import { env } from '../types/env.js'

function createR2Client(): S3Client | null {
  if (
    !env.R2_ACCOUNT_ID ||
    !env.R2_ACCESS_KEY_ID ||
    !env.R2_SECRET_ACCESS_KEY ||
    !env.R2_BUCKET_NAME
  ) {
    return null
  }

  return new S3Client({
    region: 'auto',
    endpoint: `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: env.R2_ACCESS_KEY_ID,
      secretAccessKey: env.R2_SECRET_ACCESS_KEY,
    },
  })
}

const client = createR2Client()
const bucket = env.R2_BUCKET_NAME ?? ''

export async function uploadFile(
  key: string,
  body: Buffer | Uint8Array,
  contentType: string,
): Promise<string | null> {
  if (!client) return null

  await client.send(
    new PutObjectCommand({ Bucket: bucket, Key: key, Body: body, ContentType: contentType }),
  )

  return env.R2_PUBLIC_URL ? `${env.R2_PUBLIC_URL}/${key}` : null
}

export async function deleteFile(key: string): Promise<void> {
  if (!client) return
  await client.send(new DeleteObjectCommand({ Bucket: bucket, Key: key }))
}

export async function getSignedUploadUrl(
  key: string,
  contentType: string,
  expiresIn = 3600,
): Promise<string | null> {
  if (!client) return null
  return getSignedUrl(
    client,
    new PutObjectCommand({ Bucket: bucket, Key: key, ContentType: contentType }),
    { expiresIn },
  )
}

export async function getSignedDownloadUrl(
  key: string,
  expiresIn = 3600,
): Promise<string | null> {
  if (!client) return null
  return getSignedUrl(client, new GetObjectCommand({ Bucket: bucket, Key: key }), { expiresIn })
}

export const r2 = { uploadFile, deleteFile, getSignedUploadUrl, getSignedDownloadUrl }
