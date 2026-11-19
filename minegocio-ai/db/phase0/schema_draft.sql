-- =============================================================================
-- MiNegocio AI — Esquema relacional BORRADOR (Fase 0)
-- PostgreSQL 16+
--
-- Propósito: validar el modelo de datos de docs/architecture/DATABASE_DESIGN.md
-- con un motor real antes de escribir migraciones Alembic (Fase 1).
-- NO es una migración de producción. En Fase 1 se traduce a SQLAlchemy 2 + Alembic.
--
-- Códigos de error propios (SQLSTATE clase MN):
--   MN001 mutación prohibida (append-only / inmutable)   MN002 venta sin líneas
--   MN003 totales no cuadran                               MN004 comprobante de producción en entorno no productivo
--
-- Convenciones:
--   * PK uuid. Los registros creados en el dispositivo traen su uuid (v7) desde el cliente.
--   * Toda tabla de negocio lleva business_id y UNIQUE (business_id, id) para permitir
--     claves foráneas compuestas que impiden referencias entre negocios distintos.
--   * Dinero: numeric(14,2) para importes; numeric(14,4) para precios/costos unitarios.
--   * Cantidades: numeric(14,3) (permite kg, litros, metros).
--   * Estados como text + CHECK (más fácil de migrar que tipos ENUM).
--   * Registros financieros: ON DELETE RESTRICT; se corrigen con operaciones
--     compensatorias (anulación, devolución, nota de crédito), nunca con DELETE.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- Funciones de soporte
-- -----------------------------------------------------------------------------

-- Bloquea UPDATE/DELETE en tablas append-only (kardex, auditoría, eventos).
CREATE FUNCTION forbid_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'tabla % es append-only: % no permitido', TG_TABLE_NAME, TG_OP
    USING ERRCODE = 'MN001';
END $$;

CREATE FUNCTION touch_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

-- =============================================================================
-- A. Identidad, usuarios y roles
-- =============================================================================

CREATE TABLE users (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_e164        text NOT NULL,
  email             text,
  full_name         text NOT NULL CHECK (length(btrim(full_name)) BETWEEN 1 AND 120),
  status            text NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active', 'locked', 'deleted')),
  platform_role     text CHECK (platform_role IN ('support', 'platform_admin')),
  phone_verified_at timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz,
  CONSTRAINT users_phone_format CHECK (phone_e164 ~ '^\+[1-9][0-9]{7,14}$'),
  CONSTRAINT users_email_format CHECK (email IS NULL OR email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);
CREATE UNIQUE INDEX users_phone_uq ON users (phone_e164) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX users_email_uq ON users (lower(email)) WHERE email IS NOT NULL AND deleted_at IS NULL;

-- Roles del sistema (business_id NULL) o personalizados por negocio (fase posterior).
CREATE TABLE roles (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid,                       -- FK añadida tras crear businesses
  code        text NOT NULL CHECK (code ~ '^[a-z_]{3,32}$'),
  name        text NOT NULL,
  permissions text[] NOT NULL DEFAULT '{}',
  is_system   boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT roles_code_uq UNIQUE NULLS NOT DISTINCT (business_id, code)
);

-- =============================================================================
-- B. Negocios, establecimientos y configuración
-- =============================================================================

CREATE TABLE businesses (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legal_name    text NOT NULL CHECK (length(btrim(legal_name)) BETWEEN 1 AND 200),
  trade_name    text,
  ruc           char(11) CHECK (ruc ~ '^(10|15|17|20)[0-9]{9}$'),
  tax_regime    text NOT NULL DEFAULT 'UNKNOWN'
                  CHECK (tax_regime IN ('NRUS', 'RER', 'RMT', 'GENERAL', 'UNKNOWN')),
  business_type text NOT NULL CHECK (business_type ~ '^[a-z_]{3,40}$'),
  currency      char(3) NOT NULL DEFAULT 'PEN' CHECK (currency = 'PEN'),
  timezone      text NOT NULL DEFAULT 'America/Lima',
  allow_negative_stock boolean NOT NULL DEFAULT true,
  status        text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'closed')),
  created_by    uuid NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX businesses_ruc_uq ON businesses (ruc) WHERE ruc IS NOT NULL AND status <> 'closed';

ALTER TABLE roles
  ADD CONSTRAINT roles_business_fk FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE RESTRICT;

CREATE TABLE establishments (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id      uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  name             text NOT NULL,
  address          text,
  ubigeo           char(6) CHECK (ubigeo ~ '^[0-9]{6}$'),
  sunat_annex_code char(4) CHECK (sunat_annex_code ~ '^[0-9]{4}$'),  -- PENDIENTE DE VALIDACIÓN
  is_main          boolean NOT NULL DEFAULT false,
  archived_at      timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id)
);
CREATE UNIQUE INDEX establishments_one_main ON establishments (business_id) WHERE is_main;

CREATE TABLE memberships (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id      uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  user_id          uuid NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
  role_id          uuid NOT NULL REFERENCES roles (id) ON DELETE RESTRICT,
  establishment_id uuid,  -- NULL = todos los establecimientos
  status           text NOT NULL DEFAULT 'active' CHECK (status IN ('invited', 'active', 'revoked')),
  pin_hash         text,  -- PIN corto para autorizar anulaciones en dispositivo compartido
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  UNIQUE (business_id, user_id),
  FOREIGN KEY (business_id, establishment_id) REFERENCES establishments (business_id, id) ON DELETE RESTRICT
);

-- Dispositivos registrados: unidad de sincronización y de numeración local.
CREATE TABLE devices (
  id            uuid PRIMARY KEY,
  business_id   uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  registered_by uuid NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
  device_code   smallint NOT NULL CHECK (device_code BETWEEN 1 AND 999),  -- prefijo "D03-"
  name          text NOT NULL,
  platform      text NOT NULL DEFAULT 'android' CHECK (platform IN ('android', 'ios', 'web')),
  app_version   text,
  status        text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked')),
  last_seen_at  timestamptz,
  last_pull_seq bigint NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  UNIQUE (business_id, device_code)
);

-- =============================================================================
-- D. Productos, categorías, variantes y códigos de barras
-- =============================================================================

CREATE TABLE categories (
  id          uuid PRIMARY KEY,
  business_id uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  parent_id   uuid,
  name        text NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 80),
  sort_order  integer NOT NULL DEFAULT 0,
  version     integer NOT NULL DEFAULT 1,
  archived_at timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  FOREIGN KEY (business_id, parent_id) REFERENCES categories (business_id, id) ON DELETE RESTRICT
);
CREATE UNIQUE INDEX categories_name_uq ON categories (business_id, lower(name)) WHERE archived_at IS NULL;

CREATE TABLE products (
  id                   uuid PRIMARY KEY,
  business_id          uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  category_id          uuid,
  name                 text NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 160),
  description          text,
  unit_code            text NOT NULL DEFAULT 'NIU',   -- catálogo SUNAT de unidades (validar)
  igv_affectation_code char(2) NOT NULL DEFAULT '10', -- catálogo SUNAT de afectación (validar)
  tracks_stock         boolean NOT NULL DEFAULT true,
  is_favorite          boolean NOT NULL DEFAULT false, -- aparece en la grilla de venta rápida
  image_key            text,
  version              integer NOT NULL DEFAULT 1,
  archived_at          timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  FOREIGN KEY (business_id, category_id) REFERENCES categories (business_id, id) ON DELETE RESTRICT
);
CREATE INDEX products_name_idx ON products (business_id, lower(name)) WHERE archived_at IS NULL;

CREATE TABLE product_variants (
  id          uuid PRIMARY KEY,
  business_id uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  product_id  uuid NOT NULL,
  name        text,                     -- NULL en la variante por defecto
  sku         text,
  barcode     text CHECK (barcode IS NULL OR barcode ~ '^[0-9A-Za-z\-\.]{4,64}$'),
  attributes  jsonb NOT NULL DEFAULT '{}'::jsonb,
  sale_price  numeric(14,4) NOT NULL CHECK (sale_price >= 0),  -- incluye impuestos
  avg_cost    numeric(14,4) NOT NULL DEFAULT 0 CHECK (avg_cost >= 0),
  min_stock   numeric(14,3) CHECK (min_stock IS NULL OR min_stock >= 0),
  is_default  boolean NOT NULL DEFAULT false,
  version     integer NOT NULL DEFAULT 1,
  archived_at timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  FOREIGN KEY (business_id, product_id) REFERENCES products (business_id, id) ON DELETE RESTRICT
);
CREATE UNIQUE INDEX variants_barcode_uq ON product_variants (business_id, barcode)
  WHERE barcode IS NOT NULL AND archived_at IS NULL;
CREATE UNIQUE INDEX variants_sku_uq ON product_variants (business_id, sku)
  WHERE sku IS NOT NULL AND archived_at IS NULL;
CREATE UNIQUE INDEX variants_one_default ON product_variants (product_id) WHERE is_default;

-- =============================================================================
-- E. Proveedores, compras y recepción
-- =============================================================================

CREATE TABLE suppliers (
  id          uuid PRIMARY KEY,
  business_id uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  name        text NOT NULL,
  doc_type    text NOT NULL DEFAULT 'NONE' CHECK (doc_type IN ('RUC', 'DNI', 'NONE')),
  doc_number  text,
  phone       text,
  version     integer NOT NULL DEFAULT 1,
  archived_at timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  CHECK (doc_type = 'NONE' OR doc_number IS NOT NULL),
  CHECK (doc_type <> 'RUC' OR doc_number ~ '^[0-9]{11}$'),
  CHECK (doc_type <> 'DNI' OR doc_number ~ '^[0-9]{8}$')
);

CREATE TABLE purchases (
  id                   uuid PRIMARY KEY,
  business_id          uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  establishment_id     uuid NOT NULL,
  supplier_id          uuid,
  device_id            uuid,
  status               text NOT NULL CHECK (status IN ('received', 'voided')),
  supplier_doc_kind    text CHECK (supplier_doc_kind IN ('factura', 'boleta', 'guia', 'nota', 'ninguno')),
  supplier_doc_ref     text,               -- serie-número del comprobante del proveedor
  purchase_date        date NOT NULL,
  total                numeric(14,2) NOT NULL CHECK (total >= 0),
  payment_status       text NOT NULL DEFAULT 'paid' CHECK (payment_status IN ('paid', 'pending', 'partial')),
  notes                text,
  created_by           uuid NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
  received_at          timestamptz NOT NULL,
  voided_at            timestamptz,
  void_reason          text,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  FOREIGN KEY (business_id, establishment_id) REFERENCES establishments (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, supplier_id) REFERENCES suppliers (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, device_id) REFERENCES devices (business_id, id) ON DELETE RESTRICT,
  CHECK (status <> 'voided' OR (voided_at IS NOT NULL AND void_reason IS NOT NULL))
);

CREATE TABLE purchase_items (
  id          uuid PRIMARY KEY,
  business_id uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  purchase_id uuid NOT NULL,
  variant_id  uuid NOT NULL,
  quantity    numeric(14,3) NOT NULL CHECK (quantity > 0),
  unit_cost   numeric(14,4) NOT NULL CHECK (unit_cost >= 0),
  line_total  numeric(14,2) NOT NULL CHECK (line_total >= 0),
  UNIQUE (business_id, id),
  FOREIGN KEY (business_id, purchase_id) REFERENCES purchases (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, variant_id) REFERENCES product_variants (business_id, id) ON DELETE RESTRICT
);
CREATE INDEX purchase_items_purchase_idx ON purchase_items (purchase_id);

-- =============================================================================
-- F. Inventario: kardex append-only + proyección de stock
-- =============================================================================

CREATE TABLE inventory_movements (
  id               uuid PRIMARY KEY,
  business_id      uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  establishment_id uuid NOT NULL,
  variant_id       uuid NOT NULL,
  movement_type    text NOT NULL CHECK (movement_type IN (
                     'initial', 'purchase_receipt', 'purchase_void', 'sale', 'sale_void',
                     'adjustment', 'count', 'transfer_out', 'transfer_in', 'customer_return')),
  quantity         numeric(14,3) NOT NULL CHECK (quantity <> 0),  -- con signo: + entra, - sale
  unit_cost        numeric(14,4) CHECK (unit_cost IS NULL OR unit_cost >= 0),
  source_type      text CHECK (source_type IN ('sale_item', 'purchase_item', 'adjustment', 'count', 'transfer')),
  source_id        uuid,
  reason           text,
  occurred_at      timestamptz NOT NULL,             -- reloj del dispositivo
  recorded_at      timestamptz NOT NULL DEFAULT now(), -- reloj del servidor
  device_id        uuid,
  created_by       uuid NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
  op_id            uuid,
  UNIQUE (business_id, id),
  FOREIGN KEY (business_id, establishment_id) REFERENCES establishments (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, variant_id) REFERENCES product_variants (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, device_id) REFERENCES devices (business_id, id) ON DELETE RESTRICT,
  CHECK (movement_type NOT IN ('adjustment', 'count') OR reason IS NOT NULL),
  CHECK ((source_type IS NULL) = (source_id IS NULL))
);
-- Impide descontar dos veces la misma línea de venta/compra (idempotencia de dominio).
CREATE UNIQUE INDEX inv_mov_source_uq ON inventory_movements (source_type, source_id, movement_type)
  WHERE source_id IS NOT NULL AND source_type IN ('sale_item', 'purchase_item');
CREATE INDEX inv_mov_variant_time_idx ON inventory_movements (business_id, variant_id, occurred_at);
CREATE TRIGGER inventory_movements_append_only BEFORE UPDATE OR DELETE ON inventory_movements
  FOR EACH ROW EXECUTE FUNCTION forbid_mutation();

CREATE TABLE stock_levels (
  business_id      uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  establishment_id uuid NOT NULL,
  variant_id       uuid NOT NULL,
  quantity         numeric(14,3) NOT NULL DEFAULT 0,  -- puede ser negativo (ventas offline concurrentes)
  last_movement_at timestamptz,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, establishment_id, variant_id),
  FOREIGN KEY (business_id, establishment_id) REFERENCES establishments (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, variant_id) REFERENCES product_variants (business_id, id) ON DELETE RESTRICT
);

-- Proyección: cada movimiento actualiza el stock en la misma transacción.
CREATE FUNCTION apply_inventory_movement() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO stock_levels (business_id, establishment_id, variant_id, quantity, last_movement_at)
  VALUES (NEW.business_id, NEW.establishment_id, NEW.variant_id, NEW.quantity, NEW.occurred_at)
  ON CONFLICT (business_id, establishment_id, variant_id) DO UPDATE
    SET quantity = stock_levels.quantity + EXCLUDED.quantity,
        last_movement_at = GREATEST(stock_levels.last_movement_at, EXCLUDED.last_movement_at),
        updated_at = now();
  RETURN NEW;
END $$;
CREATE TRIGGER inventory_movements_project AFTER INSERT ON inventory_movements
  FOR EACH ROW EXECUTE FUNCTION apply_inventory_movement();

-- =============================================================================
-- I. Clientes
-- =============================================================================

CREATE TABLE customers (
  id           uuid PRIMARY KEY,
  business_id  uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  doc_type     text NOT NULL DEFAULT 'NONE' CHECK (doc_type IN ('DNI', 'RUC', 'CE', 'PASAPORTE', 'NONE')),
  doc_number   text,
  name         text NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 200),
  phone        text,
  email        text,
  address      text,
  credit_limit numeric(14,2) CHECK (credit_limit IS NULL OR credit_limit >= 0),
  version      integer NOT NULL DEFAULT 1,
  archived_at  timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  CHECK (doc_type = 'NONE' OR doc_number IS NOT NULL),
  CHECK (doc_type <> 'DNI' OR doc_number ~ '^[0-9]{8}$'),
  CHECK (doc_type <> 'RUC' OR doc_number ~ '^[0-9]{11}$')
);
CREATE UNIQUE INDEX customers_doc_uq ON customers (business_id, doc_type, doc_number)
  WHERE doc_number IS NOT NULL AND archived_at IS NULL;

-- =============================================================================
-- K. Caja (sesiones de caja)
-- =============================================================================

CREATE TABLE cash_sessions (
  id               uuid PRIMARY KEY,
  business_id      uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  establishment_id uuid NOT NULL,
  device_id        uuid NOT NULL,
  opened_by        uuid NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
  opened_at        timestamptz NOT NULL,
  opening_amount   numeric(14,2) NOT NULL DEFAULT 0 CHECK (opening_amount >= 0),
  status           text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  closed_by        uuid REFERENCES users (id) ON DELETE RESTRICT,
  closed_at        timestamptz,
  expected_cash    numeric(14,2),
  counted_cash     numeric(14,2) CHECK (counted_cash IS NULL OR counted_cash >= 0),
  UNIQUE (business_id, id),
  FOREIGN KEY (business_id, establishment_id) REFERENCES establishments (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, device_id) REFERENCES devices (business_id, id) ON DELETE RESTRICT,
  CHECK (status = 'open' OR (closed_at IS NOT NULL AND closed_by IS NOT NULL AND counted_cash IS NOT NULL))
);
CREATE UNIQUE INDEX cash_sessions_one_open ON cash_sessions (device_id) WHERE status = 'open';

-- =============================================================================
-- G. Ventas
-- =============================================================================
-- Los borradores viven solo en el dispositivo. Al servidor llegan ventas 'completed'.
-- Una venta completada es inmutable; solo puede pasar a 'voided' con motivo y autorización.

CREATE TABLE sales (
  id                 uuid PRIMARY KEY,
  business_id        uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  establishment_id   uuid NOT NULL,
  device_id          uuid NOT NULL,
  cash_session_id    uuid,
  customer_id        uuid,
  local_number       text NOT NULL CHECK (local_number ~ '^D[0-9]{3}-[0-9]{6,}$'),
  mode               text NOT NULL CHECK (mode IN ('quick', 'guided', 'voice')),
  status             text NOT NULL CHECK (status IN ('completed', 'voided')),
  occurred_at        timestamptz NOT NULL,
  subtotal           numeric(14,2) NOT NULL CHECK (subtotal >= 0),   -- valor de venta (sin impuestos)
  tax_total          numeric(14,2) NOT NULL CHECK (tax_total >= 0),
  discount_total     numeric(14,2) NOT NULL DEFAULT 0 CHECK (discount_total >= 0), -- informativo
  total              numeric(14,2) NOT NULL CHECK (total >= 0),      -- precio de venta (con impuestos)
  notes              text,
  created_by         uuid NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
  voided_at          timestamptz,
  voided_by          uuid REFERENCES users (id) ON DELETE RESTRICT,
  void_authorized_by uuid REFERENCES users (id) ON DELETE RESTRICT,
  void_reason        text,
  op_id              uuid NOT NULL,
  created_at         timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  UNIQUE (business_id, device_id, local_number),
  FOREIGN KEY (business_id, establishment_id) REFERENCES establishments (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, device_id) REFERENCES devices (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, cash_session_id) REFERENCES cash_sessions (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, customer_id) REFERENCES customers (business_id, id) ON DELETE RESTRICT,
  CHECK (subtotal + tax_total = total),
  CHECK (status <> 'voided' OR (voided_at IS NOT NULL AND voided_by IS NOT NULL AND void_reason IS NOT NULL))
);
CREATE INDEX sales_business_time_idx ON sales (business_id, occurred_at DESC);
CREATE INDEX sales_customer_idx ON sales (business_id, customer_id) WHERE customer_id IS NOT NULL;

CREATE TABLE sale_items (
  id                   uuid PRIMARY KEY,
  business_id          uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  sale_id              uuid NOT NULL,
  variant_id           uuid NOT NULL,
  line_no              smallint NOT NULL CHECK (line_no >= 1),
  description_snapshot text NOT NULL,
  quantity             numeric(14,3) NOT NULL CHECK (quantity > 0),
  unit_price           numeric(14,4) NOT NULL CHECK (unit_price >= 0),  -- con impuestos
  discount             numeric(14,2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
  igv_affectation_code char(2) NOT NULL,
  tax_rate             numeric(5,4) NOT NULL CHECK (tax_rate >= 0 AND tax_rate < 1),
  line_subtotal        numeric(14,2) NOT NULL CHECK (line_subtotal >= 0),
  line_tax             numeric(14,2) NOT NULL CHECK (line_tax >= 0),
  line_total           numeric(14,2) NOT NULL CHECK (line_total >= 0),
  unit_cost_snapshot   numeric(14,4) NOT NULL DEFAULT 0 CHECK (unit_cost_snapshot >= 0),
  UNIQUE (business_id, id),
  UNIQUE (sale_id, line_no),
  FOREIGN KEY (business_id, sale_id) REFERENCES sales (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, variant_id) REFERENCES product_variants (business_id, id) ON DELETE RESTRICT,
  CHECK (line_subtotal + line_tax = line_total),
  CHECK (line_total = round(quantity * unit_price, 2) - discount)
);
CREATE TRIGGER sale_items_immutable BEFORE UPDATE OR DELETE ON sale_items
  FOR EACH ROW EXECUTE FUNCTION forbid_mutation();

-- Totales de la cabecera = suma de líneas (verificado al COMMIT).
CREATE FUNCTION check_sale_totals() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_sale_id uuid;
  s record;
  agg record;
BEGIN
  -- PL/pgSQL resuelve los campos de NEW aunque la rama no se ejecute: usar IF, no CASE.
  IF TG_TABLE_NAME = 'sales' THEN
    v_sale_id := NEW.id;
  ELSE
    v_sale_id := NEW.sale_id;
  END IF;
  SELECT subtotal, tax_total, total INTO s FROM sales WHERE id = v_sale_id;
  SELECT coalesce(sum(line_subtotal), 0) AS st, coalesce(sum(line_tax), 0) AS tx,
         coalesce(sum(line_total), 0) AS tt, count(*) AS n
    INTO agg FROM sale_items WHERE sale_id = v_sale_id;
  IF agg.n = 0 THEN
    RAISE EXCEPTION 'venta % sin líneas', v_sale_id USING ERRCODE = 'MN002';
  END IF;
  IF s.subtotal <> agg.st OR s.tax_total <> agg.tx OR s.total <> agg.tt THEN
    RAISE EXCEPTION 'venta %: totales de cabecera (%/%/%) no cuadran con líneas (%/%/%)',
      v_sale_id, s.subtotal, s.tax_total, s.total, agg.st, agg.tx, agg.tt USING ERRCODE = 'MN003';
  END IF;
  RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER sales_totals_check AFTER INSERT ON sales
  DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_sale_totals();
CREATE CONSTRAINT TRIGGER sale_items_totals_check AFTER INSERT ON sale_items
  DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_sale_totals();

-- Venta completada: solo se permite la transición completed -> voided.
CREATE FUNCTION guard_sale_update() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'las ventas no se eliminan; anule con motivo' USING ERRCODE = 'MN001';
  END IF;
  IF OLD.status = 'voided' THEN
    RAISE EXCEPTION 'venta % ya anulada', OLD.id USING ERRCODE = 'MN001';
  END IF;
  IF NEW.status <> 'voided'
     OR (NEW.subtotal, NEW.tax_total, NEW.total, NEW.occurred_at, NEW.device_id,
         NEW.local_number, NEW.business_id, NEW.customer_id, NEW.created_by)
        IS DISTINCT FROM
        (OLD.subtotal, OLD.tax_total, OLD.total, OLD.occurred_at, OLD.device_id,
         OLD.local_number, OLD.business_id, OLD.customer_id, OLD.created_by) THEN
    RAISE EXCEPTION 'venta % es inmutable: solo se permite anular', OLD.id USING ERRCODE = 'MN001';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER sales_guard BEFORE UPDATE OR DELETE ON sales
  FOR EACH ROW EXECUTE FUNCTION guard_sale_update();

-- =============================================================================
-- H. Cobros y métodos de pago
-- =============================================================================

CREATE TABLE payments (
  id               uuid PRIMARY KEY,
  business_id      uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  establishment_id uuid NOT NULL,
  sale_id          uuid,
  customer_id      uuid,
  cash_session_id  uuid,
  device_id        uuid,
  kind             text NOT NULL DEFAULT 'payment' CHECK (kind IN ('payment', 'refund')),
  method           text NOT NULL CHECK (method IN ('cash', 'yape', 'plin', 'card', 'transfer', 'other')),
  amount           numeric(14,2) NOT NULL CHECK (amount > 0),
  tendered         numeric(14,2) CHECK (tendered IS NULL OR tendered >= amount), -- efectivo entregado
  reference        text,          -- n.º de operación Yape/Plin/POS
  status           text NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'voided')),
  received_at      timestamptz NOT NULL,
  recorded_by      uuid NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
  reconciled_at    timestamptz,
  reconciled_by    uuid REFERENCES users (id) ON DELETE RESTRICT,
  void_reason      text,
  op_id            uuid NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  FOREIGN KEY (business_id, establishment_id) REFERENCES establishments (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, sale_id) REFERENCES sales (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, customer_id) REFERENCES customers (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, cash_session_id) REFERENCES cash_sessions (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, device_id) REFERENCES devices (business_id, id) ON DELETE RESTRICT,
  CHECK (sale_id IS NOT NULL OR customer_id IS NOT NULL),
  CHECK (status <> 'voided' OR void_reason IS NOT NULL),
  CHECK (method <> 'cash' OR reference IS NULL OR length(reference) <= 64)
);
CREATE INDEX payments_sale_idx ON payments (sale_id) WHERE sale_id IS NOT NULL;
CREATE INDEX payments_customer_idx ON payments (business_id, customer_id) WHERE customer_id IS NOT NULL;

CREATE FUNCTION guard_payment_update() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'los cobros no se eliminan; anule con motivo' USING ERRCODE = 'MN001';
  END IF;
  IF (NEW.amount, NEW.method, NEW.kind, NEW.sale_id, NEW.customer_id, NEW.business_id, NEW.received_at)
     IS DISTINCT FROM
     (OLD.amount, OLD.method, OLD.kind, OLD.sale_id, OLD.customer_id, OLD.business_id, OLD.received_at) THEN
    RAISE EXCEPTION 'cobro % es inmutable (solo anulación o conciliación)', OLD.id USING ERRCODE = 'MN001';
  END IF;
  IF OLD.status = 'voided' AND NEW.status <> 'voided' THEN
    RAISE EXCEPTION 'cobro % anulado no puede reactivarse', OLD.id USING ERRCODE = 'MN001';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER payments_guard BEFORE UPDATE OR DELETE ON payments
  FOR EACH ROW EXECUTE FUNCTION guard_payment_update();

-- =============================================================================
-- K. Gastos
-- =============================================================================

CREATE TABLE expenses (
  id               uuid PRIMARY KEY,
  business_id      uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  establishment_id uuid NOT NULL,
  cash_session_id  uuid,
  supplier_id      uuid,
  device_id        uuid,
  category         text NOT NULL CHECK (category ~ '^[a-z_]{3,40}$'),
  description      text,
  amount           numeric(14,2) NOT NULL CHECK (amount > 0),
  payment_method   text NOT NULL CHECK (payment_method IN ('cash', 'yape', 'plin', 'card', 'transfer', 'other')),
  occurred_at      timestamptz NOT NULL,
  receipt_image_key text,
  status           text NOT NULL DEFAULT 'recorded' CHECK (status IN ('recorded', 'voided')),
  void_reason      text,
  created_by       uuid NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
  op_id            uuid NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  FOREIGN KEY (business_id, establishment_id) REFERENCES establishments (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, cash_session_id) REFERENCES cash_sessions (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, supplier_id) REFERENCES suppliers (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, device_id) REFERENCES devices (business_id, id) ON DELETE RESTRICT,
  CHECK (status <> 'voided' OR void_reason IS NOT NULL)
);
CREATE INDEX expenses_business_time_idx ON expenses (business_id, occurred_at DESC);

-- =============================================================================
-- J. Facturación electrónica
-- =============================================================================
-- Regla de oro: una venta registrada NO es un comprobante tributario. El comprobante
-- solo es 'accepted'/'observed' si existe evidencia válida (CDR u otra constancia).

CREATE TABLE invoice_series (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id      uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  establishment_id uuid NOT NULL,
  doc_type         char(2) NOT NULL CHECK (doc_type IN ('01', '03', '07', '08')),
  series           char(4) NOT NULL CHECK (series ~ '^[FB][A-Z0-9]{3}$'),  -- PENDIENTE DE VALIDACIÓN
  next_number      integer NOT NULL DEFAULT 1 CHECK (next_number BETWEEN 1 AND 99999999),
  environment      text NOT NULL CHECK (environment IN ('test', 'production')),
  active           boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  UNIQUE (business_id, environment, doc_type, series),
  FOREIGN KEY (business_id, establishment_id) REFERENCES establishments (business_id, id) ON DELETE RESTRICT,
  CHECK (doc_type <> '01' OR series LIKE 'F%'),
  CHECK (doc_type <> '03' OR series LIKE 'B%')
);

CREATE TABLE invoices (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id            uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  establishment_id       uuid NOT NULL,
  sale_id                uuid,
  related_invoice_id     uuid,           -- obligatorio en notas de crédito/débito
  doc_type               char(2) NOT NULL CHECK (doc_type IN ('01', '03', '07', '08')),
  series                 char(4) NOT NULL,
  number                 integer NOT NULL CHECK (number BETWEEN 1 AND 99999999),
  environment            text NOT NULL CHECK (environment IN ('test', 'production')),
  status                 text NOT NULL DEFAULT 'queued' CHECK (status IN (
                           'queued', 'submitting', 'accepted', 'observed', 'rejected',
                           'failed_retryable', 'unknown', 'voided')),
  issue_date             date NOT NULL,
  currency               char(3) NOT NULL DEFAULT 'PEN',
  customer_doc_type      text NOT NULL,
  customer_doc_number    text,
  customer_name          text NOT NULL,
  subtotal               numeric(14,2) NOT NULL CHECK (subtotal >= 0),
  tax_total              numeric(14,2) NOT NULL CHECK (tax_total >= 0),
  total                  numeric(14,2) NOT NULL CHECK (total >= 0),
  note_reason_code       char(2),
  note_reason_text       text,
  provider               text NOT NULL,       -- 'fake', 'pse_x', 'ose_y', 'see_contribuyente'
  provider_document_id   text,
  payload_hash           text,                -- hash del XML/JSON enviado
  evidence_type          text CHECK (evidence_type IN ('cdr', 'provider_status', 'summary_ticket')),
  evidence_ref           text,                -- clave en almacenamiento de objetos (WORM)
  evidence_received_at   timestamptz,
  sunat_response_code    text,
  sunat_response_message text,
  pdf_key                text,
  attempt_count          integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at        timestamptz,
  requested_by           uuid NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, id),
  UNIQUE (business_id, environment, doc_type, series, number),
  FOREIGN KEY (business_id, establishment_id) REFERENCES establishments (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, sale_id) REFERENCES sales (business_id, id) ON DELETE RESTRICT,
  FOREIGN KEY (business_id, related_invoice_id) REFERENCES invoices (business_id, id) ON DELETE RESTRICT,
  CHECK (subtotal + tax_total = total),
  CHECK ((doc_type IN ('07', '08')) = (related_invoice_id IS NOT NULL)),
  CHECK (doc_type NOT IN ('07', '08') OR note_reason_code IS NOT NULL),
  CHECK (doc_type NOT IN ('01', '03') OR sale_id IS NOT NULL),
  -- Nunca "aceptado" sin evidencia.
  CHECK (status NOT IN ('accepted', 'observed')
         OR (evidence_type IS NOT NULL AND evidence_ref IS NOT NULL AND evidence_received_at IS NOT NULL)),
  -- Factura exige RUC del adquirente.
  CHECK (doc_type <> '01' OR (customer_doc_type = 'RUC' AND customer_doc_number ~ '^[0-9]{11}$'))
);
-- Una venta tiene a lo sumo un comprobante vigente (los rechazados pueden reemitirse).
CREATE UNIQUE INDEX invoices_one_live_per_sale ON invoices (sale_id)
  WHERE doc_type IN ('01', '03') AND status NOT IN ('rejected', 'voided');
CREATE INDEX invoices_pending_idx ON invoices (next_attempt_at)
  WHERE status IN ('queued', 'failed_retryable', 'unknown');
CREATE TRIGGER invoices_touch BEFORE UPDATE ON invoices
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- Defensa en profundidad: la base de datos rechaza comprobantes de producción si la
-- instancia no está marcada como producción (ALTER DATABASE ... SET app.deploy_env).
CREATE FUNCTION guard_invoice_environment() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.environment = 'production'
     AND coalesce(current_setting('app.deploy_env', true), '') <> 'production' THEN
    RAISE EXCEPTION 'comprobante de producción bloqueado en entorno "%"',
      coalesce(current_setting('app.deploy_env', true), 'sin definir') USING ERRCODE = 'MN004';
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.status IN ('accepted', 'observed', 'rejected', 'voided')
     AND NEW.status <> OLD.status AND NOT (OLD.status IN ('accepted', 'observed') AND NEW.status = 'voided') THEN
    RAISE EXCEPTION 'transición de estado inválida % -> %', OLD.status, NEW.status USING ERRCODE = 'MN001';
  END IF;
  IF TG_OP = 'UPDATE' AND (NEW.doc_type, NEW.series, NEW.number, NEW.total, NEW.environment)
       IS DISTINCT FROM (OLD.doc_type, OLD.series, OLD.number, OLD.total, OLD.environment) THEN
    RAISE EXCEPTION 'identidad e importes del comprobante son inmutables' USING ERRCODE = 'MN001';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER invoices_guard BEFORE INSERT OR UPDATE ON invoices
  FOR EACH ROW EXECUTE FUNCTION guard_invoice_environment();
CREATE TRIGGER invoices_no_delete BEFORE DELETE ON invoices
  FOR EACH ROW EXECUTE FUNCTION forbid_mutation();

CREATE TABLE invoice_events (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id  uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  invoice_id   uuid NOT NULL,
  event_type   text NOT NULL CHECK (event_type IN (
                 'requested', 'submitted', 'provider_response', 'status_polled', 'accepted',
                 'observed', 'rejected', 'retry_scheduled', 'error', 'pdf_generated',
                 'delivered', 'void_requested', 'voided')),
  from_status  text,
  to_status    text,
  payload      jsonb NOT NULL DEFAULT '{}'::jsonb,  -- sin secretos ni datos personales innecesarios
  raw_ref      text,                                 -- respuesta cruda en almacenamiento de objetos
  actor        text NOT NULL,                        -- 'system' | 'user:<uuid>'
  occurred_at  timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (business_id, invoice_id) REFERENCES invoices (business_id, id) ON DELETE RESTRICT
);
CREATE INDEX invoice_events_invoice_idx ON invoice_events (invoice_id, occurred_at);
CREATE TRIGGER invoice_events_append_only BEFORE UPDATE OR DELETE ON invoice_events
  FOR EACH ROW EXECUTE FUNCTION forbid_mutation();

-- =============================================================================
-- L. Dashboard personalizable
-- =============================================================================

CREATE TABLE dashboard_preferences (
  id            uuid PRIMARY KEY,
  business_id   uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  membership_id uuid,  -- NULL = configuración por defecto del negocio
  template_code text NOT NULL,
  layout        jsonb NOT NULL CHECK (jsonb_typeof(layout) = 'array'),
  version       integer NOT NULL DEFAULT 1,
  updated_by_device uuid,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE NULLS NOT DISTINCT (business_id, membership_id),
  FOREIGN KEY (business_id, membership_id) REFERENCES memberships (business_id, id) ON DELETE CASCADE
);

-- =============================================================================
-- M. Sincronización offline-first
-- =============================================================================

-- Bitácora de operaciones recibidas (inbox idempotente). op_id lo genera el dispositivo.
CREATE TABLE sync_events (
  op_id             uuid PRIMARY KEY,
  business_id       uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  device_id         uuid NOT NULL,
  device_seq        bigint NOT NULL CHECK (device_seq >= 1),
  op_type           text NOT NULL CHECK (op_type ~ '^[a-z_]+\.[a-z_]+$'),  -- 'sale.complete'
  entity_type       text NOT NULL,
  entity_id         uuid NOT NULL,
  payload           jsonb NOT NULL,
  payload_hash      text NOT NULL,
  status            text NOT NULL CHECK (status IN ('applied', 'rejected', 'needs_review')),
  result            jsonb NOT NULL DEFAULT '{}'::jsonb,
  error_code        text,
  client_created_at timestamptz NOT NULL,
  client_clock_skew_ms integer,
  received_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (device_id, device_seq),
  FOREIGN KEY (business_id, device_id) REFERENCES devices (business_id, id) ON DELETE RESTRICT,
  CHECK (status = 'applied' OR error_code IS NOT NULL)
);
CREATE INDEX sync_events_business_idx ON sync_events (business_id, received_at);
CREATE INDEX sync_events_attention_idx ON sync_events (business_id) WHERE status <> 'applied';

-- Fuente de cambios para pull incremental (cursor = seq).
CREATE TABLE sync_changes (
  seq          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id  uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  entity_type  text NOT NULL,
  entity_id    uuid NOT NULL,
  change_type  text NOT NULL CHECK (change_type IN ('upsert', 'archive')),
  entity_version integer,
  origin_op_id uuid,
  origin_device_id uuid,
  changed_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX sync_changes_cursor_idx ON sync_changes (business_id, seq);
CREATE TRIGGER sync_changes_append_only BEFORE UPDATE OR DELETE ON sync_changes
  FOR EACH ROW EXECUTE FUNCTION forbid_mutation();

-- =============================================================================
-- N. Suscripciones y planes
-- =============================================================================

CREATE TABLE plans (
  code        text PRIMARY KEY CHECK (code ~ '^[a-z0-9_]{2,32}$'),
  name        text NOT NULL,
  limits      jsonb NOT NULL DEFAULT '{}'::jsonb,  -- {"devices":1,"products":300,"ai_ops_month":0}
  price_month numeric(10,2) NOT NULL CHECK (price_month >= 0),  -- precio PENDIENTE de decisión comercial
  active      boolean NOT NULL DEFAULT true
);

CREATE TABLE subscriptions (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id          uuid NOT NULL REFERENCES businesses (id) ON DELETE RESTRICT,
  plan_code            text NOT NULL REFERENCES plans (code) ON DELETE RESTRICT,
  status               text NOT NULL CHECK (status IN ('trialing', 'active', 'past_due', 'canceled', 'expired')),
  current_period_start timestamptz NOT NULL,
  current_period_end   timestamptz NOT NULL,
  trial_ends_at        timestamptz,
  provider             text,
  provider_ref         text,
  canceled_at          timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  CHECK (current_period_end > current_period_start)
);
CREATE UNIQUE INDEX subscriptions_one_live ON subscriptions (business_id)
  WHERE status IN ('trialing', 'active', 'past_due');

-- =============================================================================
-- Auditoría
-- =============================================================================

CREATE TABLE audit_logs (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id     uuid REFERENCES businesses (id) ON DELETE RESTRICT,  -- NULL = evento de plataforma
  actor_type      text NOT NULL CHECK (actor_type IN ('user', 'system', 'support', 'ai')),
  actor_user_id   uuid REFERENCES users (id) ON DELETE RESTRICT,
  actor_device_id uuid,
  action          text NOT NULL CHECK (action ~ '^[a-z_]+\.[a-z_]+$'),  -- 'sale.void'
  entity_type     text,
  entity_id       uuid,
  before          jsonb,
  after           jsonb,
  reason          text,
  ip              inet,
  request_id      text,
  occurred_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_logs_business_time_idx ON audit_logs (business_id, occurred_at DESC);
CREATE INDEX audit_logs_entity_idx ON audit_logs (entity_type, entity_id);
CREATE TRIGGER audit_logs_append_only BEFORE UPDATE OR DELETE ON audit_logs
  FOR EACH ROW EXECUTE FUNCTION forbid_mutation();

-- =============================================================================
-- Aislamiento multiempresa con Row Level Security (defensa en profundidad)
-- La API fija:  SET LOCAL app.business_id = '<uuid>'  en cada transacción.
-- =============================================================================

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'establishments', 'memberships', 'devices', 'categories', 'products', 'product_variants',
    'suppliers', 'purchases', 'purchase_items', 'inventory_movements', 'stock_levels',
    'customers', 'cash_sessions', 'sales', 'sale_items', 'payments', 'expenses',
    'invoice_series', 'invoices', 'invoice_events', 'dashboard_preferences',
    'sync_events', 'sync_changes', 'subscriptions'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format(
      'CREATE POLICY tenant_isolation ON %I USING (business_id = nullif(current_setting(''app.business_id'', true), '''')::uuid) '
      'WITH CHECK (business_id = nullif(current_setting(''app.business_id'', true), '''')::uuid)', t);
  END LOOP;
END $$;

-- Roles iniciales del sistema (permisos detallados en docs/requirements/MODULE_SPECS.md).
INSERT INTO roles (code, name, is_system, permissions) VALUES
  ('owner', 'Dueño', true, ARRAY['*']),
  ('admin', 'Administrador', true, ARRAY['catalog.*', 'inventory.*', 'sales.*', 'payments.*',
     'purchases.*', 'customers.*', 'expenses.*', 'reports.read', 'invoices.issue', 'members.manage']),
  ('cashier', 'Vendedor', true, ARRAY['catalog.read', 'sales.create', 'payments.create',
     'customers.create', 'customers.read', 'inventory.read', 'cash.operate', 'invoices.issue']),
  ('accountant', 'Contador (solo lectura)', true, ARRAY['reports.read', 'invoices.read',
     'sales.read', 'purchases.read', 'expenses.read']);

INSERT INTO plans (code, name, limits, price_month) VALUES
  ('free', 'Gratis', '{"devices":1,"establishments":1,"products":200,"invoices_month":0,"ai_ops_month":0}', 0);

COMMIT;
