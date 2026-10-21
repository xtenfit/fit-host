import { NextResponse } from 'next/server';
import { z } from 'zod';
import { getSupabaseClient } from '@/lib/supabase';
import { generateOtp, getOtpExpiryMinutes } from '@/lib/otp';
import { sendVerificationEmail } from '@/lib/email';

const bodySchema = z.object({
  name: z.string().min(1).max(120),
  email: z.string().email(),
  company: z.string().max(160).optional().default(''),
});

export async function POST(request: Request) {
  try {
    const json = await request.json();
    const parsed = bodySchema.safeParse(json);

    if (!parsed.success) {
      return NextResponse.json(
        { error: 'Please provide a valid name and email address.' },
        { status: 400 }
      );
    }

    const { name, email, company } = parsed.data;
    const otp = generateOtp(6);
    const expiresAt = new Date(Date.now() + getOtpExpiryMinutes() * 60 * 1000).toISOString();
    const supabase = getSupabaseClient();

    const { error: insertError } = await supabase.from('email_verifications').upsert([
      {
        email,
        name,
        company,
        otp,
        expires_at: expiresAt,
        created_at: new Date().toISOString(),
      },
    ], {
      onConflict: 'email',
      ignoreDuplicates: false,
    });

    if (insertError) {
      console.error('Supabase insert error:', insertError);
      return NextResponse.json(
        { error: 'Unable to save verification data.' },
        { status: 500 }
      );
    }

    const emailResult = await sendVerificationEmail({ name, email, otp });

    if (emailResult.error) {
      console.error('Resend email error:', emailResult.error);
      return NextResponse.json(
        { error: 'Verification email could not be sent.' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Verification email sent successfully.',
      email,
    });
  } catch (error) {
    console.error('OTP send route error:', error);
    return NextResponse.json(
      { error: 'Failed to process verification request.' },
      { status: 500 }
    );
  }
}
