import { NextResponse } from 'next/server';
import { z } from 'zod';
import { getSupabaseClient } from '@/lib/supabase';
import { hashPassword } from '@/lib/password';
import { generateOtp, getOtpExpiryMinutes } from '@/lib/otp';
import { sendVerificationEmail } from '@/lib/email';

const bodySchema = z.object({
  name: z.string().min(1).max(120),
  email: z.string().email(),
  company: z.string().max(160).optional().default(''),
  password: z.string().min(8).max(200),
});

export async function POST(request: Request) {
  try {
    const json = await request.json();
    const parsed = bodySchema.safeParse(json);

    if (!parsed.success) {
      return NextResponse.json(
        { error: 'Please provide a valid name, email, and password.' },
        { status: 400 }
      );
    }

    const { name, email, company, password } = parsed.data;
    const supabase = getSupabaseClient();

    const passwordHash = await hashPassword(password);

    const { data: existingUser, error: userLookupError } = await supabase
      .from('users')
      .select('id')
      .eq('email', email)
      .maybeSingle();

    if (userLookupError) {
      console.error('User lookup error:', userLookupError);
      return NextResponse.json({ error: 'Signup failed.' }, { status: 500 });
    }

    if (existingUser) {
      return NextResponse.json(
        { error: 'This email is already registered.' },
        { status: 409 }
      );
    }

    const { error: insertUserError } = await supabase.from('users').insert([
      {
        email,
        name,
        company,
        password_hash: passwordHash,
        is_verified: false,
      },
    ]);

    if (insertUserError) {
      console.error('User insert error:', insertUserError);
      return NextResponse.json({ error: 'Unable to create user.' }, { status: 500 });
    }

    const otp = generateOtp(6);
    const expiresAt = new Date(Date.now() + getOtpExpiryMinutes() * 60 * 1000).toISOString();

    const { error: otpError } = await supabase.from('email_verifications').upsert([
      {
        email,
        otp,
        expires_at: expiresAt,
        created_at: new Date().toISOString(),
      },
    ], {
      onConflict: 'email',
      ignoreDuplicates: false,
    });

    if (otpError) {
      console.error('OTP save error:', otpError);
      return NextResponse.json({ error: 'Failed to save verification code.' }, { status: 500 });
    }

    const emailResult = await sendVerificationEmail({ name, email, otp });

    if (emailResult.error) {
      console.error('Resend email error:', emailResult.error);
      return NextResponse.json({ error: 'Could not send verification email.' }, { status: 500 });
    }

    return NextResponse.json({
      success: true,
      message: 'Signup created. Please verify your email with the code sent to your inbox.',
      email,
    });
  } catch (error) {
    console.error('Signup route error:', error);
    return NextResponse.json({ error: 'Signup failed.' }, { status: 500 });
  }
}
