import { createClient } from '@supabase/supabase-js';

/**
 * BOOTSTRAP DEVELOPER SCRIPT
 * 
 * Usage: 
 * 1. Set your SERVICE_ROLE_KEY and URL below
 * 2. Run with node: `node bootstrap.js admin@mapy.com your_secure_password`
 */

const SUPABASE_URL = 'https://admnocqbnyvhmzseehek.supabase.co';
const SERVICE_ROLE_KEY = process.argv[4] || process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SERVICE_ROLE_KEY) {
  console.error('Error: Please provide the Service Role Key as an argument or env var.');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function bootstrap() {
  const email = process.argv[2];
  const password = process.argv[3];

  if (!email || !password) {
    console.error('Usage: node bootstrap.js <email> <password> <service_role_key>');
    process.exit(1);
  }

  console.log(`🚀 Bootstrapping developer: ${email}...`);

  // 1. Create the Auth User
  let { data: userData, error: userError } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: 'Developer Admin' }
  });

  if (userError && userError.message.includes('already been registered')) {
    console.log('ℹ️ User already exists. Fetching existing account...');
    const { data: listData, error: listError } = await supabase.auth.admin.listUsers();
    if (listError) {
      console.error('❌ Failed to list users:', listError.message);
      return;
    }
    const existingUser = listData.users.find(u => u.email === email);
    if (!existingUser) {
      console.error('❌ User found in error but not in list. Check permissions.');
      return;
    }
    userData = { user: existingUser };
    console.log('✅ Found existing user:', existingUser.id);
  } else if (userError) {
    console.error('❌ Failed to create auth user:', userError.message);
    return;
  }

  const userId = userData.user.id;
  console.log('✅ Auth user created:', userId);

  // 2. Set as Admin in Profiles
  // Note: This assumes the profiles table exists and has an is_admin column
  const { error: profileError } = await supabase
    .from('profiles')
    .upsert({ 
      id: userId, 
      is_admin: true,
      username: 'admin_' + Math.floor(Math.random() * 1000)
    });

  if (profileError) {
    console.error('❌ Failed to set admin flag:', profileError.message);
    console.log('⚠️ Make sure you ran the SQL script in schema_update.sql first!');
  } else {
    console.log('🎉 SUCCESS! Developer account is ready.');
  }
}

bootstrap();
