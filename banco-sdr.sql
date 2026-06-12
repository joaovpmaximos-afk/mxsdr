-- ============================================================
-- Maximos SDR — BANCO DE DADOS (Supabase)
-- Usa o MESMO projeto Supabase da Agenda (tkvbytnbuoimhebbixwk),
-- com tabelas próprias (prefixo sdr_). Nada da Agenda é alterado.
--
-- COMO RODAR (2 minutos, uma vez só):
--   1. Abra https://supabase.com/dashboard e entre na sua conta.
--   2. Abra o projeto da Agenda.
--   3. Menu esquerdo: "SQL Editor" -> "New query".
--   4. Cole TODO este arquivo e clique em "Run".
--   5. Depois: menu "Authentication" -> "Users" -> "Add user"
--        Email:    equipe@maximossdr.app
--        Password: (crie a senha do escritório — a equipe vai usá-la
--                   uma vez por computador para entrar)
--        Marque "Auto Confirm User".
--   6. Me avise que o script rodou — eu ligo o sistema no banco.
-- ============================================================

-- EMPRESAS (clientes para os quais o material é gerado)
create table if not exists public.sdr_empresas (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  cnpj text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- EQUIPE (nomes das SDRs que aparecem na tela de entrada)
create table if not exists public.sdr_equipe (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  created_at timestamptz not null default now()
);

-- HISTÓRICO (cada geração de material)
create table if not exists public.sdr_historico (
  id uuid primary key default gen_random_uuid(),
  ts timestamptz not null default now(),
  sdr text not null default '',
  empresa_id uuid references public.sdr_empresas(id) on delete set null,
  empresa_nome text not null default '',
  tipo text not null default 'docs',
  material text not null default '',
  cadencia text not null default '',
  txt text not null default '',
  chat jsonb not null default '[]'::jsonb
);

-- CONFIGURAÇÕES COMPARTILHADAS (modelo do prompt etc.)
create table if not exists public.sdr_config (
  chave text primary key,
  valor text not null default '',
  updated_at timestamptz not null default now()
);

-- Índices úteis
create index if not exists sdr_historico_ts_idx on public.sdr_historico (ts desc);
create index if not exists sdr_historico_empresa_idx on public.sdr_historico (empresa_id);

-- updated_at automático nas empresas
create or replace function public.sdr_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists sdr_empresas_touch on public.sdr_empresas;
create trigger sdr_empresas_touch before update on public.sdr_empresas
  for each row execute function public.sdr_touch_updated_at();

-- ============================================================
-- SEGURANÇA (RLS): só quem entrou com a senha do escritório
-- (usuário autenticado) pode ler/gravar. Visitante anônimo: nada.
-- ============================================================
alter table public.sdr_empresas  enable row level security;
alter table public.sdr_equipe    enable row level security;
alter table public.sdr_historico enable row level security;
alter table public.sdr_config    enable row level security;

drop policy if exists "equipe_tudo_empresas"  on public.sdr_empresas;
drop policy if exists "equipe_tudo_equipe"    on public.sdr_equipe;
drop policy if exists "equipe_tudo_historico" on public.sdr_historico;
drop policy if exists "equipe_tudo_config"    on public.sdr_config;

create policy "equipe_tudo_empresas"  on public.sdr_empresas  for all to authenticated using (true) with check (true);
create policy "equipe_tudo_equipe"    on public.sdr_equipe    for all to authenticated using (true) with check (true);
create policy "equipe_tudo_historico" on public.sdr_historico for all to authenticated using (true) with check (true);
create policy "equipe_tudo_config"    on public.sdr_config    for all to authenticated using (true) with check (true);

-- Confirmação
select 'Tabelas do Maximos SDR criadas com sucesso!' as resultado;
