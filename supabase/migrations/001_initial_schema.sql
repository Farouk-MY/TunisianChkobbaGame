  -- Supabase SQL Migration: Chkobba Online Multiplayer
  -- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)

  -- ═══════════════════════════════════════════════════════════════════════════
  -- 1. PROFILES TABLE
  -- ═══════════════════════════════════════════════════════════════════════════

  CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL DEFAULT 'Joueur',
    avatar_url TEXT,
    elo_rating INT NOT NULL DEFAULT 1000,
    games_played INT NOT NULL DEFAULT 0,
    games_won INT NOT NULL DEFAULT 0,
    total_chkobbas INT NOT NULL DEFAULT 0,
    highest_score INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );

  -- Auto-create profile on user signup
  CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS TRIGGER AS $$
  BEGIN
    INSERT INTO public.profiles (id, display_name, avatar_url)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'full_name', 'Joueur'),
      NEW.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
  CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

  -- ═══════════════════════════════════════════════════════════════════════════
  -- 2. MATCHES TABLE
  -- ═══════════════════════════════════════════════════════════════════════════

  CREATE TABLE IF NOT EXISTS public.matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_code TEXT UNIQUE NOT NULL,
    host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    guest_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'waiting'
      CHECK (status IN ('waiting', 'playing', 'finished', 'cancelled', 'rematch_pending')),
    target_score INT NOT NULL DEFAULT 21,
    winner_id UUID REFERENCES public.profiles(id),
    host_score INT NOT NULL DEFAULT 0,
    guest_score INT NOT NULL DEFAULT 0,
    rematch_host BOOLEAN NOT NULL DEFAULT false,
    rematch_guest BOOLEAN NOT NULL DEFAULT false,
    parent_match_id UUID REFERENCES public.matches(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at TIMESTAMPTZ
  );

  -- Index for fast match-code lookups
  CREATE INDEX IF NOT EXISTS idx_matches_code ON public.matches(match_code);
  -- Index for finding waiting matches
  CREATE INDEX IF NOT EXISTS idx_matches_status ON public.matches(status) WHERE status = 'waiting';

  -- ═══════════════════════════════════════════════════════════════════════════
  -- 3. LEADERBOARD VIEW
  -- ═══════════════════════════════════════════════════════════════════════════

  CREATE OR REPLACE VIEW public.leaderboard AS
    SELECT
      id,
      display_name,
      avatar_url,
      elo_rating,
      games_played,
      games_won,
      CASE WHEN games_played > 0
        THEN ROUND((games_won::NUMERIC / games_played) * 100)
        ELSE 0
      END AS win_rate
    FROM public.profiles
    WHERE games_played > 0
    ORDER BY elo_rating DESC
    LIMIT 100;

  -- ═══════════════════════════════════════════════════════════════════════════
  -- 4. ROW-LEVEL SECURITY (RLS)
  -- ═══════════════════════════════════════════════════════════════════════════

  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

  -- Profiles: anyone can read, only owner can update
  CREATE POLICY "Profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

  CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

  CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

  -- Matches: anyone can read, host can create/update, guest can join
  CREATE POLICY "Matches are viewable by everyone"
    ON public.matches FOR SELECT
    USING (true);

  CREATE POLICY "Authenticated users can create matches"
    ON public.matches FOR INSERT
    WITH CHECK (auth.uid() = host_id);

  CREATE POLICY "Match participants can update"
    ON public.matches FOR UPDATE
    USING (auth.uid() = host_id OR auth.uid() = guest_id);

  -- ═══════════════════════════════════════════════════════════════════════════
  -- 5. REALTIME (enable for matches table)
  -- ═══════════════════════════════════════════════════════════════════════════

  -- Enable realtime for the matches table
  ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
