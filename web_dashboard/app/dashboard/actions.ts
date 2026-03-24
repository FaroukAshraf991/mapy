'use server'

import { getSupabaseAdmin } from "@/lib/supabase";
import { revalidatePath } from "next/cache";

export async function updateUserMetadata(userId: string, metadata: { username?: string; date_of_birth?: string }) {
  const supabase = getSupabaseAdmin();
  
  // 1. Update Profile Table
  const { error: profileError } = await supabase
    .from('profiles')
    .update({ 
      username: metadata.username,
      date_of_birth: metadata.date_of_birth 
    })
    .eq('id', userId);

  if (profileError) {
    return { success: false, error: profileError.message };
  }

  revalidatePath('/dashboard/users');
  return { success: true };
}

export async function resetUserPassword(userId: string, newPassword: string) {
  const supabase = getSupabaseAdmin();

  const { error } = await supabase.auth.admin.updateUserById(
    userId,
    { password: newPassword }
  );

  if (error) {
    return { success: false, error: error.message };
  }

  return { success: true };
}

export async function toggleUserBan(userId: string, shouldBan: boolean) {
  const supabase = getSupabaseAdmin();

  const { error } = await supabase.auth.admin.updateUserById(
    userId,
    { ban_duration: shouldBan ? '87600h' : 'none' } // 10 years or none
  );

  if (error) {
    return { success: false, error: error.message };
  }

  revalidatePath('/dashboard/users');
  return { success: true };
}
