-- ============================================================
-- RPC for deleting user account
-- Execute este SQL no Supabase Dashboard → SQL Editor
-- ============================================================

CREATE OR REPLACE FUNCTION delete_user()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
  -- Deleta o usuário da tabela auth.users.
  -- O ON DELETE CASCADE configurado na tabela profiles
  -- garantirá que os dados de profiles e relacionadas sejam apagados.
  DELETE FROM auth.users WHERE id = auth.uid();
$$;
