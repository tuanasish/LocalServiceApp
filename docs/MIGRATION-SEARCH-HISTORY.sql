-- ============================================
-- MIGRATION: Search History Table
-- Version: 1.0
-- ============================================

-- Tạo bảng search_history
CREATE TABLE IF NOT EXISTS public.search_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  query text NOT NULL,
  search_type text, -- 'product', 'shop', 'all'
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS search_history_user_idx 
  ON public.search_history(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS search_history_query_idx 
  ON public.search_history(query);

-- RLS Policies
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;

-- Users chỉ có thể xem/search history của chính họ
CREATE POLICY "Users can view own search history"
  ON public.search_history
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own search history"
  ON public.search_history
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own search history"
  ON public.search_history
  FOR DELETE
  USING (auth.uid() = user_id);
