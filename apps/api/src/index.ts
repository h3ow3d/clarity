// Placeholder API entry point
export const handler = async (
  _event: unknown
): Promise<{ statusCode: number; body: string }> => {
  // TODO: Implement actual handler logic

  return {
    statusCode: 200,
    body: JSON.stringify({ message: 'Hello from Clarity API' }),
  };
};
