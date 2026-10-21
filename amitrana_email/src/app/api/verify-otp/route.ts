import { NextResponse } from 'next/server';
import { z } from 'zod';
import { getSupabaseClient } from '@/lib/supabase';

const bodySchema = z.object({
  email: z.string().email(),
  otp: z.string().min(6).max(6),
});

export async function POST(request: Request) {
  try {
    const json = await request.json();
    const parsed = bodySchema.safeParse(json);

    if (!parsed.success) {
      return NextResponse.json(
        { error: 'Valid email and OTP are required.' },
        { status: 400 }
      );
    }

    const { email, otp } = parsed.data;
    const supabase = getSupabaseClient();

    const { data, error } = await supabase
      .from('email_verifications')
      .select('*')
      .eq('email', email)
      .single();

    if (error || !data) {
      return NextResponse.json(
        { error: 'No verification record found.' },
        { status: 404 }
      );
    }

    const now = new Date();
    const expiresAt = new Date(data.expires_at);

    if (now > expiresAt) {
      return NextResponse.json(
        { error: 'OTP has expired. Please request a new code.' },
        { status: 410 }
      );
    }

    if (data.otp !== otp) {
      return NextResponse.json(
        { error: 'Incorrect OTP. Please try again.' },
        { status: 401 }
      );
    }

    await supabase
      .from('email_verifications')
      .update({ verified_at: new Date().toISOString(), is_verified: true })
      .eq('email', email);

    return NextResponse.json({
      success: true,
      message: 'Email verified successfully.',
      email,
    });
  } catch (error) {
    console.error('OTP verify route error:', error);
    return NextResponse.json(
      { error: 'Failed to verify OTP.' },
      { status: 500 }
    );
  }
}
