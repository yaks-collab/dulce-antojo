-- Dulce Antojo · tablas y reglas de seguridad para Supabase
-- Pégalo completo en Supabase → SQL Editor → New query → Run.

-- ============ Clientes ============
-- Un registro por cuenta, con los datos de entrega.
create table if not exists public.clientes (
  id uuid primary key references auth.users (id) on delete cascade,
  nombre text not null,
  telefono text not null,
  direccion text not null,
  barrio text,
  acepta_datos boolean not null default false,  -- autorización Ley 1581 de 2012
  creado_en timestamptz not null default now()
);

alter table public.clientes enable row level security;

-- Cada cliente solo ve y edita sus propios datos.
create policy "ver mis datos" on public.clientes
  for select to authenticated using (id = auth.uid());
create policy "crear mis datos" on public.clientes
  for insert to authenticated with check (id = auth.uid());
create policy "editar mis datos" on public.clientes
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

revoke all on public.clientes from anon, authenticated;
grant select, insert, update on public.clientes to authenticated;

-- ============ Pedidos ============
create table if not exists public.pedidos (
  id bigint generated always as identity primary key,
  cliente_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  productos jsonb not null,       -- [{ id, nombre, precio, cantidad }]
  total integer not null check (total >= 0),
  direccion text,
  estado text not null default 'recibido'
    check (estado in ('recibido', 'confirmado', 'en_camino', 'entregado', 'cancelado')),
  creado_en timestamptz not null default now()
);

create index if not exists pedidos_cliente_idx on public.pedidos (cliente_id, creado_en desc);

alter table public.pedidos enable row level security;

-- Cada cliente solo ve sus pedidos y solo puede crear pedidos a su nombre.
create policy "ver mis pedidos" on public.pedidos
  for select to authenticated using (cliente_id = auth.uid());
create policy "crear mis pedidos" on public.pedidos
  for insert to authenticated with check (cliente_id = auth.uid());

-- El cliente solo puede llenar estas columnas; el estado lo cambia la tienda
-- desde el Table Editor de Supabase (recibido → confirmado → en_camino → entregado).
revoke all on public.pedidos from anon, authenticated;
grant select on public.pedidos to authenticated;
grant insert (productos, total, direccion) on public.pedidos to authenticated;
