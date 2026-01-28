import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const FIREBASE_SERVICE_ACCOUNT = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')

serve(async (req) => {
  try {
    const { record } = await req.json()
    
    if (!record || !record.user_id) {
      return new Response(JSON.stringify({ error: 'Missing record data' }), { status: 400 })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Get user's FCM tokens
    const { data: tokens, error: tokensError } = await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', record.user_id)

    if (tokensError) throw tokensError
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No tokens found for user' }), { status: 200 })
    }

    if (!FIREBASE_SERVICE_ACCOUNT) {
      return new Response(JSON.stringify({ error: 'FIREBASE_SERVICE_ACCOUNT not configured' }), { status: 500 })
    }

    const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT)
    const accessToken = await getAccessToken(serviceAccount)

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`

    const results = await Promise.all(tokens.map(async (t) => {
      const response = await fetch(fcmUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: t.token,
            notification: {
              title: record.title,
              body: record.body,
            },
            data: {
              ...record.data,
              notification_id: record.id,
            },
            android: {
              priority: 'high',
              notification: {
                channel_id: 'high_importance_channel',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              }
            }
          }
        })
      })
      return response.json()
    }))

    return new Response(JSON.stringify({ results }), { 
      headers: { 'Content-Type': 'application/json' },
      status: 200 
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})

// Helper to get Google OAuth2 access token
async function getAccessToken(serviceAccount: any): Promise<string> {
  const HEADER = { alg: "RS256", typ: "JWT" };
  const NOW = Math.floor(Date.now() / 1000);
  const EXPIRE = NOW + 3600;

  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: NOW,
    exp: EXPIRE,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const encodedHeader = b64(JSON.stringify(HEADER));
  const encodedPayload = b64(JSON.stringify(payload));
  const signatureInput = `${encodedHeader}.${encodedPayload}`;
  
  const privateKey = serviceAccount.private_key.replace(/\\n/g, '\n');
  const key = await crypto.subtle.importKey(
    "pkcs8",
    str2ab(atob(privateKey.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n/g, ""))),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signatureInput)
  );

  const jwt = `${signatureInput}.${b64ab(signature)}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const result = await response.json();
  return result.access_token;
}

function b64(str: string) {
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

function b64ab(ab: ArrayBuffer) {
  const uint8 = new Uint8Array(ab);
  let binary = "";
  for (let i = 0; i < uint8.length; i++) {
    binary += String.fromCharCode(uint8[i]);
  }
  return b64(binary);
}

function str2ab(str: string) {
  const buf = new ArrayBuffer(str.length);
  const bufView = new Uint8Array(buf);
  for (let i = 0, strLen = str.length; i < strLen; i++) {
    bufView[i] = str.charCodeAt(i);
  }
  return buf;
}
