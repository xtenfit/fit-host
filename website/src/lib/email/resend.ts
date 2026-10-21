import { Resend } from 'resend';
import { SendEmailOptions, SendEmailResult } from './types';
import { emailStore } from './store';

// Default sender identities based on discovered domain and provider setup
export const DEFAULT_EMAIL_FROM = process.env.EMAIL_FROM || 'Fit Host <no-reply@noreply.amitrana.tech>';
export const DEFAULT_EMAIL_REPLY_TO = process.env.EMAIL_REPLY_TO || 'support@amitrana.tech';
export const SENDING_DOMAIN = 'noreply.amitrana.tech';

function getResendClient(): Resend | null {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey || apiKey.trim() === '' || apiKey.includes('your-resend-api-key')) {
    return null;
  }
  return new Resend(apiKey);
}

/**
 * Validates an email address format safely.
 */
export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

/**
 * Sends an email using the Resend provider with deliverability safeguards,
 * suppression checks, and delivery audit logging.
 */
export async function sendEmail(options: SendEmailOptions): Promise<SendEmailResult> {
  const {
    to,
    subject,
    html,
    text,
    from = DEFAULT_EMAIL_FROM,
    replyTo = DEFAULT_EMAIL_REPLY_TO,
    tags = [],
    templateId,
    workflowId,
    isTest = false,
  } = options;

  const recipients = Array.isArray(to) ? to : [to];

  // 1. Validate recipients
  for (const recipient of recipients) {
    if (!isValidEmail(recipient)) {
      return {
        success: false,
        error: `Invalid email recipient address: ${recipient}`,
        isTest,
      };
    }

    // 2. Check suppression list (unsubscribes, hard bounces)
    const isSuppressed = await emailStore.isSuppressed(recipient);
    if (isSuppressed && !isTest) {
      await emailStore.recordDeliveryEvent({
        recipient_email: recipient,
        subject,
        template_id: templateId,
        workflow_id: workflowId,
        provider: 'resend',
        event_type: 'suppressed',
        error_message: 'Recipient is on the suppression list (unsubscribed or previous bounce).',
      });

      return {
        success: false,
        error: `Delivery suppressed: ${recipient} has unsubscribed or is suppressed.`,
        isTest,
      };
    }
  }

  const finalSubject = isTest ? `[TEST] ${subject}` : subject;

  // 3. Obtain Resend client
  const resend = getResendClient();

  if (!resend) {
    // If no live API key is configured yet, record a simulated delivery for local verification
    const simulatedId = `sim_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;

    for (const recipient of recipients) {
      await emailStore.recordDeliveryEvent({
        recipient_email: recipient,
        subject: finalSubject,
        template_id: templateId,
        workflow_id: workflowId,
        provider: 'resend (simulated)',
        provider_message_id: simulatedId,
        event_type: 'delivered',
        metadata: {
          simulated: true,
          notice: 'No RESEND_API_KEY environment variable detected; delivery was simulated in development mode.',
        },
      });
    }

    return {
      success: true,
      messageId: simulatedId,
      isTest,
    };
  }

  // 4. Live send via Resend
  try {
    const response = await resend.emails.send({
      from,
      to: recipients,
      replyTo,
      subject: finalSubject,
      html,
      text: text || undefined,
      tags: [
        ...tags,
        { name: 'app', value: 'fit-host' },
        ...(isTest ? [{ name: 'mode', value: 'test' }] : []),
        ...(templateId ? [{ name: 'template_id', value: templateId }] : []),
      ],
    });

    if (response.error) {
      for (const recipient of recipients) {
        await emailStore.recordDeliveryEvent({
          recipient_email: recipient,
          subject: finalSubject,
          template_id: templateId,
          workflow_id: workflowId,
          provider: 'resend',
          event_type: 'failed',
          error_message: response.error.message,
        });
      }

      return {
        success: false,
        error: response.error.message,
        isTest,
      };
    }

    const messageId = response.data?.id || `res_${Date.now()}`;

    for (const recipient of recipients) {
      await emailStore.recordDeliveryEvent({
        recipient_email: recipient,
        subject: finalSubject,
        template_id: templateId,
        workflow_id: workflowId,
        provider: 'resend',
        provider_message_id: messageId,
        event_type: 'sent',
      });
    }

    return {
      success: true,
      messageId,
      isTest,
    };
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : 'Unknown email send error';

    for (const recipient of recipients) {
      await emailStore.recordDeliveryEvent({
        recipient_email: recipient,
        subject: finalSubject,
        template_id: templateId,
        workflow_id: workflowId,
        provider: 'resend',
        event_type: 'failed',
        error_message: errorMsg,
      });
    }

    return {
      success: false,
      error: errorMsg,
      isTest,
    };
  }
}
