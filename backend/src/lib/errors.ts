export const ErrorCodes = {
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  BAD_REQUEST: 'BAD_REQUEST',
  RATE_LIMITED: 'RATE_LIMITED',
  USAGE_LIMIT_REACHED: 'USAGE_LIMIT_REACHED',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  INVALID_SIGNATURE: 'INVALID_SIGNATURE',
} as const

export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes]

export class AppError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: ErrorCode | string,
    message: string,
  ) {
    super(message)
    this.name = 'AppError'
  }
}
