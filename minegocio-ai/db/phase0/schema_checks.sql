-- =============================================================================
-- MiNegocio AI — Pruebas del esquema borrador (Fase 0)
-- Ejecutar con:  tools/check_schema.sh   (crea una base temporal, carga el esquema
-- y ejecuta estas aserciones; cualquier FAIL aborta con código distinto de cero).
-- =============================================================================
\set ON_ERROR_STOP 1
\o /dev/null
SET client_min_messages = notice;

-- ---------- utilidades de prueba ----------
CREATE FUNCTION test_assert(cond boolean, label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF cond IS NOT TRUE THEN RAISE EXCEPTION 'FAIL %', label; END IF;
  RAISE NOTICE 'PASS %', label;
END $$;

-- Ejecuta las sentencias en un subbloque y exige el SQLSTATE indicado.
-- Al final fuerza la verificación de restricciones diferidas.
CREATE FUNCTION test_expect_error(stmts text[], expected_state text, label text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE s text;
BEGIN
  BEGIN
    FOREACH s IN ARRAY stmts LOOP EXECUTE s; END LOOP;
    SET CONSTRAINTS ALL IMMEDIATE;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = expected_state THEN
      RAISE NOTICE 'PASS % (% %)', label, SQLSTATE, left(SQLERRM, 90);
      RETURN;
    END IF;
    RAISE EXCEPTION 'FAIL %: se esperaba %, se obtuvo % (%)', label, expected_state, SQLSTATE, SQLERRM;
  END;
  RAISE EXCEPTION 'FAIL %: se esperaba el error % y no ocurrió', label, expected_state;
END $$;

CREATE FUNCTION test_expect_ok(stmts text[], label text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE s text;
BEGIN
  FOREACH s IN ARRAY stmts LOOP EXECUTE s; END LOOP;
  SET CONSTRAINTS ALL IMMEDIATE;
  RAISE NOTICE 'PASS %', label;
END $$;

-- ---------- datos base: dos negocios aislados ----------
INSERT INTO users (id, phone_e164, full_name) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', '+51987654321', 'Dueña Bodega A'),
  ('aaaaaaaa-0000-0000-0000-000000000002', '+51912345678', 'Dueño Ferretería B');

INSERT INTO businesses (id, legal_name, business_type, tax_regime, ruc, created_by) VALUES
  ('b0000000-0000-0000-0000-00000000000a', 'Bodega A', 'bodega', 'RMT', '10456789012', 'aaaaaaaa-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-00000000000b', 'Ferretería B', 'ferreteria', 'NRUS', NULL, 'aaaaaaaa-0000-0000-0000-000000000002');

INSERT INTO establishments (id, business_id, name, is_main) VALUES
  ('e0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-00000000000a', 'Principal', true),
  ('e0000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-00000000000b', 'Principal', true);

INSERT INTO devices (id, business_id, registered_by, device_code, name) VALUES
  ('d0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', 1, 'Celular caja'),
  ('d0000000-0000-0000-0000-0000000000a2', 'b0000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001', 2, 'Celular hija'),
  ('d0000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-00000000000b', 'aaaaaaaa-0000-0000-0000-000000000002', 1, 'Celular');

INSERT INTO products (id, business_id, name) VALUES
  ('c0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-00000000000a', 'Gaseosa 500 ml'),
  ('c0000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-00000000000b', 'Clavo 2"');

INSERT INTO product_variants (id, business_id, product_id, sale_price, avg_cost, is_default, barcode) VALUES
  ('f0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-00000000000a', 'c0000000-0000-0000-0000-00000000000a', 2.5000, 1.8000, true, '7750000000011'),
  ('f0000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-00000000000b', 'c0000000-0000-0000-0000-00000000000b', 0.1000, 0.0600, true, '7750000000011');

SELECT test_assert(true, 'T00 mismo código de barras permitido en negocios distintos');

-- ---------- T01 aislamiento por claves foráneas compuestas ----------
SELECT test_expect_error(ARRAY[
  $q$INSERT INTO sales (id, business_id, establishment_id, device_id, local_number, mode, status, occurred_at,
       subtotal, tax_total, total, created_by, op_id)
     VALUES ('5a1e0000-0000-0000-0000-0000000000f1', 'b0000000-0000-0000-0000-00000000000a',
       'e0000000-0000-0000-0000-00000000000b', 'd0000000-0000-0000-0000-00000000000a', 'D001-000099', 'quick',
       'completed', now(), 0, 0, 0, 'aaaaaaaa-0000-0000-0000-000000000001', gen_random_uuid())$q$
], '23503', 'T01 venta del negocio A no puede usar establecimiento del negocio B');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO sales (id, business_id, establishment_id, device_id, local_number, mode, status, occurred_at,
       subtotal, tax_total, total, created_by, op_id)
     VALUES ('5a1e0000-0000-0000-0000-0000000000f2', 'b0000000-0000-0000-0000-00000000000a',
       'e0000000-0000-0000-0000-00000000000a', 'd0000000-0000-0000-0000-00000000000a', 'D001-000098', 'quick',
       'completed', now(), 0.08, 0.02, 0.10, 'aaaaaaaa-0000-0000-0000-000000000001', gen_random_uuid())$q$,
  $q$INSERT INTO sale_items (id, business_id, sale_id, variant_id, line_no, description_snapshot, quantity,
       unit_price, igv_affectation_code, tax_rate, line_subtotal, line_tax, line_total)
     VALUES (gen_random_uuid(), 'b0000000-0000-0000-0000-00000000000a', '5a1e0000-0000-0000-0000-0000000000f2',
       'f0000000-0000-0000-0000-00000000000b', 1, 'Clavo', 1, 0.1, '10', 0.18, 0.08, 0.02, 0.10)$q$
], '23503', 'T02 línea de venta no puede referenciar variante de otro negocio');

-- ---------- T03 venta válida con IGV incluido y stock negativo permitido ----------
SELECT test_expect_ok(ARRAY[
  $q$INSERT INTO sales (id, business_id, establishment_id, device_id, local_number, mode, status, occurred_at,
       subtotal, tax_total, total, created_by, op_id)
     VALUES ('5a1e0000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-00000000000a',
       'e0000000-0000-0000-0000-00000000000a', 'd0000000-0000-0000-0000-00000000000a', 'D001-000001', 'quick',
       'completed', now(), 8.47, 1.53, 10.00, 'aaaaaaaa-0000-0000-0000-000000000001',
       '0b000000-0000-0000-0000-000000000001')$q$,
  $q$INSERT INTO sale_items (id, business_id, sale_id, variant_id, line_no, description_snapshot, quantity,
       unit_price, igv_affectation_code, tax_rate, line_subtotal, line_tax, line_total, unit_cost_snapshot)
     VALUES ('1e000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-00000000000a',
       '5a1e0000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-00000000000a', 1, 'Gaseosa 500 ml',
       4, 2.5, '10', 0.18, 8.47, 1.53, 10.00, 1.8)$q$,
  $q$INSERT INTO inventory_movements (id, business_id, establishment_id, variant_id, movement_type, quantity,
       source_type, source_id, occurred_at, device_id, created_by)
     VALUES ('a1000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-00000000000a',
       'e0000000-0000-0000-0000-00000000000a', 'f0000000-0000-0000-0000-00000000000a', 'sale', -4,
       'sale_item', '1e000000-0000-0000-0000-000000000001', now(), 'd0000000-0000-0000-0000-00000000000a',
       'aaaaaaaa-0000-0000-0000-000000000001')$q$
], 'T03 venta 4 x S/2.50 = S/10.00 (valor 8.47 + IGV 1.53) registrada');

SELECT test_assert(
  (SELECT quantity FROM stock_levels WHERE variant_id = 'f0000000-0000-0000-0000-00000000000a') = -4,
  'T04 proyección de stock refleja la venta (stock -4: negativo permitido y visible para alerta)');

-- ---------- T05 cuadre de totales ----------
SELECT test_expect_error(ARRAY[
  $q$INSERT INTO sales (id, business_id, establishment_id, device_id, local_number, mode, status, occurred_at,
       subtotal, tax_total, total, created_by, op_id)
     VALUES ('5a1e0000-0000-0000-0000-0000000000f3', 'b0000000-0000-0000-0000-00000000000a',
       'e0000000-0000-0000-0000-00000000000a', 'd0000000-0000-0000-0000-00000000000a', 'D001-000097', 'quick',
       'completed', now(), 16.95, 3.05, 20.00, 'aaaaaaaa-0000-0000-0000-000000000001', gen_random_uuid())$q$,
  $q$INSERT INTO sale_items (id, business_id, sale_id, variant_id, line_no, description_snapshot, quantity,
       unit_price, igv_affectation_code, tax_rate, line_subtotal, line_tax, line_total)
     VALUES (gen_random_uuid(), 'b0000000-0000-0000-0000-00000000000a', '5a1e0000-0000-0000-0000-0000000000f3',
       'f0000000-0000-0000-0000-00000000000a', 1, 'Gaseosa', 4, 2.5, '10', 0.18, 8.47, 1.53, 10.00)$q$
], 'MN003', 'T05 cabecera (S/20.00) que no cuadra con líneas (S/10.00) se rechaza al confirmar');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO sales (id, business_id, establishment_id, device_id, local_number, mode, status, occurred_at,
       subtotal, tax_total, total, created_by, op_id)
     VALUES ('5a1e0000-0000-0000-0000-0000000000f4', 'b0000000-0000-0000-0000-00000000000a',
       'e0000000-0000-0000-0000-00000000000a', 'd0000000-0000-0000-0000-00000000000a', 'D001-000096', 'quick',
       'completed', now(), 0, 0, 0, 'aaaaaaaa-0000-0000-0000-000000000001', gen_random_uuid())$q$
], 'MN002', 'T06 venta sin líneas se rechaza');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO sales (id, business_id, establishment_id, device_id, local_number, mode, status, occurred_at,
       subtotal, tax_total, total, created_by, op_id)
     VALUES ('5a1e0000-0000-0000-0000-0000000000f5', 'b0000000-0000-0000-0000-00000000000a',
       'e0000000-0000-0000-0000-00000000000a', 'd0000000-0000-0000-0000-00000000000a', 'D001-000095', 'quick',
       'completed', now(), 8.47, 1.53, 10.00, 'aaaaaaaa-0000-0000-0000-000000000001', gen_random_uuid())$q$,
  $q$INSERT INTO sale_items (id, business_id, sale_id, variant_id, line_no, description_snapshot, quantity,
       unit_price, igv_affectation_code, tax_rate, line_subtotal, line_tax, line_total)
     VALUES (gen_random_uuid(), 'b0000000-0000-0000-0000-00000000000a', '5a1e0000-0000-0000-0000-0000000000f5',
       'f0000000-0000-0000-0000-00000000000a', 1, 'Gaseosa', 3, 2.5, '10', 0.18, 8.47, 1.53, 10.00)$q$
], '23514', 'T07 línea cuyo total no es cantidad x precio - descuento se rechaza');

-- ---------- T08 idempotencia de inventario ----------
SELECT test_expect_error(ARRAY[
  $q$INSERT INTO inventory_movements (id, business_id, establishment_id, variant_id, movement_type, quantity,
       source_type, source_id, occurred_at, created_by)
     VALUES (gen_random_uuid(), 'b0000000-0000-0000-0000-00000000000a', 'e0000000-0000-0000-0000-00000000000a',
       'f0000000-0000-0000-0000-00000000000a', 'sale', -4, 'sale_item', '1e000000-0000-0000-0000-000000000001',
       now(), 'aaaaaaaa-0000-0000-0000-000000000001')$q$
], '23505', 'T08 la misma línea de venta no descuenta stock dos veces');

SELECT test_expect_error(ARRAY[
  $q$DELETE FROM inventory_movements WHERE id = 'a1000000-0000-0000-0000-000000000001'$q$
], 'MN001', 'T09 el kardex es append-only (DELETE bloqueado)');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO inventory_movements (id, business_id, establishment_id, variant_id, movement_type, quantity,
       occurred_at, created_by)
     VALUES (gen_random_uuid(), 'b0000000-0000-0000-0000-00000000000a', 'e0000000-0000-0000-0000-00000000000a',
       'f0000000-0000-0000-0000-00000000000a', 'adjustment', -1, now(), 'aaaaaaaa-0000-0000-0000-000000000001')$q$
], '23514', 'T10 ajuste de inventario sin motivo se rechaza');

-- ---------- T11 inmutabilidad de ventas y anulación auditable ----------
SELECT test_expect_error(ARRAY[
  $q$UPDATE sales SET total = 5, subtotal = 4.24, tax_total = 0.76 WHERE id = '5a1e0000-0000-0000-0000-000000000001'$q$
], 'MN001', 'T11 no se puede editar el importe de una venta completada');

SELECT test_expect_error(ARRAY[
  $q$UPDATE sales SET status = 'voided' WHERE id = '5a1e0000-0000-0000-0000-000000000001'$q$
], '23514', 'T12 anular sin motivo ni responsable se rechaza');

SELECT test_expect_error(ARRAY[
  $q$UPDATE sale_items SET quantity = 1 WHERE id = '1e000000-0000-0000-0000-000000000001'$q$
], 'MN001', 'T13 las líneas de venta son inmutables');

SELECT test_expect_error(ARRAY[
  $q$DELETE FROM sales WHERE id = '5a1e0000-0000-0000-0000-000000000001'$q$
], 'MN001', 'T14 las ventas no se eliminan');

-- ---------- T15 cobros ----------
SELECT test_expect_ok(ARRAY[
  $q$INSERT INTO payments (id, business_id, establishment_id, sale_id, method, amount, tendered, received_at,
       recorded_by, op_id)
     VALUES ('9a000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-00000000000a',
       'e0000000-0000-0000-0000-00000000000a', '5a1e0000-0000-0000-0000-000000000001', 'cash', 10.00, 20.00,
       now(), 'aaaaaaaa-0000-0000-0000-000000000001', gen_random_uuid())$q$
], 'T15 cobro en efectivo con vuelto (entregó S/20.00)');

SELECT test_expect_error(ARRAY[
  $q$UPDATE payments SET amount = 9 WHERE id = '9a000000-0000-0000-0000-000000000001'$q$
], 'MN001', 'T16 el importe de un cobro es inmutable');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO payments (id, business_id, establishment_id, method, amount, received_at, recorded_by, op_id)
     VALUES (gen_random_uuid(), 'b0000000-0000-0000-0000-00000000000a', 'e0000000-0000-0000-0000-00000000000a',
       'yape', 5, now(), 'aaaaaaaa-0000-0000-0000-000000000001', gen_random_uuid())$q$
], '23514', 'T17 un cobro debe asociarse a una venta o a un cliente');

-- Anulación correcta de la venta (compensación).
SELECT test_expect_ok(ARRAY[
  $q$UPDATE payments SET status = 'voided', void_reason = 'venta anulada' WHERE id = '9a000000-0000-0000-0000-000000000001'$q$,
  $q$UPDATE sales SET status = 'voided', voided_at = now(), voided_by = 'aaaaaaaa-0000-0000-0000-000000000001',
       void_reason = 'cliente devolvió producto' WHERE id = '5a1e0000-0000-0000-0000-000000000001'$q$,
  $q$INSERT INTO inventory_movements (id, business_id, establishment_id, variant_id, movement_type, quantity,
       source_type, source_id, occurred_at, created_by)
     VALUES (gen_random_uuid(), 'b0000000-0000-0000-0000-00000000000a', 'e0000000-0000-0000-0000-00000000000a',
       'f0000000-0000-0000-0000-00000000000a', 'sale_void', 4, 'sale_item', '1e000000-0000-0000-0000-000000000001',
       now(), 'aaaaaaaa-0000-0000-0000-000000000001')$q$
], 'T18 anulación con motivo + cobro anulado + movimiento compensatorio');

SELECT test_assert(
  (SELECT quantity FROM stock_levels WHERE variant_id = 'f0000000-0000-0000-0000-00000000000a') = 0,
  'T19 stock vuelve a 0 tras el movimiento compensatorio');

SELECT test_expect_error(ARRAY[
  $q$UPDATE sales SET notes = 'x' WHERE id = '5a1e0000-0000-0000-0000-000000000001'$q$
], 'MN001', 'T20 una venta anulada no se vuelve a modificar');

-- ---------- T21 sincronización idempotente ----------
SELECT test_expect_ok(ARRAY[
  $q$INSERT INTO sync_events (op_id, business_id, device_id, device_seq, op_type, entity_type, entity_id, payload,
       payload_hash, status, client_created_at)
     VALUES ('0b000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-00000000000a',
       'd0000000-0000-0000-0000-00000000000a', 1, 'sale.complete', 'sale', '5a1e0000-0000-0000-0000-000000000001',
       '{}', 'sha256:abc', 'applied', now())$q$
], 'T21 operación de sincronización registrada');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO sync_events (op_id, business_id, device_id, device_seq, op_type, entity_type, entity_id, payload,
       payload_hash, status, client_created_at)
     VALUES ('0b000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-00000000000a',
       'd0000000-0000-0000-0000-00000000000a', 2, 'sale.complete', 'sale', '5a1e0000-0000-0000-0000-000000000001',
       '{}', 'sha256:abc', 'applied', now())$q$
], '23505', 'T22 reenvío del mismo op_id detectado (el servidor responde con el resultado guardado)');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO sync_events (op_id, business_id, device_id, device_seq, op_type, entity_type, entity_id, payload,
       payload_hash, status, client_created_at)
     VALUES (gen_random_uuid(), 'b0000000-0000-0000-0000-00000000000a',
       'd0000000-0000-0000-0000-00000000000a', 1, 'sale.complete', 'sale', gen_random_uuid(),
       '{}', 'sha256:def', 'applied', now())$q$
], '23505', 'T23 secuencia de dispositivo duplicada detectada');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO sales (id, business_id, establishment_id, device_id, local_number, mode, status, occurred_at,
       subtotal, tax_total, total, created_by, op_id)
     VALUES (gen_random_uuid(), 'b0000000-0000-0000-0000-00000000000a',
       'e0000000-0000-0000-0000-00000000000a', 'd0000000-0000-0000-0000-00000000000a', 'D001-000001', 'quick',
       'completed', now(), 8.47, 1.53, 10.00, 'aaaaaaaa-0000-0000-0000-000000000001', gen_random_uuid())$q$
], '23505', 'T24 número local de venta único por dispositivo');

-- Dos dispositivos del mismo negocio pueden usar el mismo correlativo local (prefijo distinto).
SELECT test_expect_ok(ARRAY[
  $q$INSERT INTO sales (id, business_id, establishment_id, device_id, local_number, mode, status, occurred_at,
       subtotal, tax_total, total, created_by, op_id)
     VALUES ('5a1e0000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-00000000000a',
       'e0000000-0000-0000-0000-00000000000a', 'd0000000-0000-0000-0000-0000000000a2', 'D002-000001', 'quick',
       'completed', now(), 2.12, 0.38, 2.50, 'aaaaaaaa-0000-0000-0000-000000000001', gen_random_uuid())$q$,
  $q$INSERT INTO sale_items (id, business_id, sale_id, variant_id, line_no, description_snapshot, quantity,
       unit_price, igv_affectation_code, tax_rate, line_subtotal, line_tax, line_total)
     VALUES (gen_random_uuid(), 'b0000000-0000-0000-0000-00000000000a', '5a1e0000-0000-0000-0000-000000000002',
       'f0000000-0000-0000-0000-00000000000a', 1, 'Gaseosa 500 ml', 1, 2.5, '10', 0.18, 2.12, 0.38, 2.50)$q$
], 'T25 segundo dispositivo vende offline sin colisión de numeración');

-- ---------- T26 comprobantes electrónicos ----------
SELECT test_expect_error(ARRAY[
  $q$INSERT INTO invoices (business_id, establishment_id, sale_id, doc_type, series, number, environment, status,
       issue_date, customer_doc_type, customer_name, subtotal, tax_total, total, provider, requested_by)
     VALUES ('b0000000-0000-0000-0000-00000000000a', 'e0000000-0000-0000-0000-00000000000a',
       '5a1e0000-0000-0000-0000-000000000002', '03', 'B001', 1, 'test', 'accepted', current_date, 'NONE',
       'Clientes varios', 2.12, 0.38, 2.50, 'fake', 'aaaaaaaa-0000-0000-0000-000000000001')$q$
], '23514', 'T26 un comprobante no puede quedar "aceptado" sin evidencia');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO invoices (business_id, establishment_id, sale_id, doc_type, series, number, environment, status,
       issue_date, customer_doc_type, customer_name, subtotal, tax_total, total, provider, requested_by)
     VALUES ('b0000000-0000-0000-0000-00000000000a', 'e0000000-0000-0000-0000-00000000000a',
       '5a1e0000-0000-0000-0000-000000000002', '03', 'B001', 2, 'production', 'queued', current_date, 'NONE',
       'Clientes varios', 2.12, 0.38, 2.50, 'pse_x', 'aaaaaaaa-0000-0000-0000-000000000001')$q$
], 'MN004', 'T27 comprobante de producción bloqueado en base de datos de prueba');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO invoices (business_id, establishment_id, sale_id, doc_type, series, number, environment, status,
       issue_date, customer_doc_type, customer_doc_number, customer_name, subtotal, tax_total, total, provider, requested_by)
     VALUES ('b0000000-0000-0000-0000-00000000000a', 'e0000000-0000-0000-0000-00000000000a',
       '5a1e0000-0000-0000-0000-000000000002', '01', 'F001', 1, 'test', 'queued', current_date, 'DNI', '12345678',
       'Cliente', 2.12, 0.38, 2.50, 'fake', 'aaaaaaaa-0000-0000-0000-000000000001')$q$
], '23514', 'T28 factura sin RUC del adquirente se rechaza');

SELECT test_expect_ok(ARRAY[
  $q$INSERT INTO invoices (id, business_id, establishment_id, sale_id, doc_type, series, number, environment, status,
       issue_date, customer_doc_type, customer_name, subtotal, tax_total, total, provider, requested_by)
     VALUES ('1a000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-00000000000a',
       'e0000000-0000-0000-0000-00000000000a', '5a1e0000-0000-0000-0000-000000000002', '03', 'B001', 1, 'test',
       'queued', current_date, 'NONE', 'Clientes varios', 2.12, 0.38, 2.50, 'fake',
       'aaaaaaaa-0000-0000-0000-000000000001')$q$,
  $q$UPDATE invoices SET status = 'submitting' WHERE id = '1a000000-0000-0000-0000-000000000001'$q$,
  $q$UPDATE invoices SET status = 'accepted', evidence_type = 'cdr', evidence_ref = 'evidence/test/abc.zip',
       evidence_received_at = now(), sunat_response_code = '0' WHERE id = '1a000000-0000-0000-0000-000000000001'$q$
], 'T29 boleta de prueba: queued -> submitting -> accepted con evidencia');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO invoices (business_id, establishment_id, sale_id, doc_type, series, number, environment, status,
       issue_date, customer_doc_type, customer_name, subtotal, tax_total, total, provider, requested_by)
     VALUES ('b0000000-0000-0000-0000-00000000000a', 'e0000000-0000-0000-0000-00000000000a',
       '5a1e0000-0000-0000-0000-000000000002', '03', 'B001', 2, 'test', 'queued', current_date, 'NONE',
       'Clientes varios', 2.12, 0.38, 2.50, 'fake', 'aaaaaaaa-0000-0000-0000-000000000001')$q$
], '23505', 'T30 una venta no puede tener dos comprobantes vigentes');

SELECT test_expect_error(ARRAY[
  $q$UPDATE invoices SET number = 7 WHERE id = '1a000000-0000-0000-0000-000000000001'$q$
], 'MN001', 'T31 serie, número e importes del comprobante son inmutables');

SELECT test_expect_error(ARRAY[
  $q$UPDATE invoices SET status = 'queued' WHERE id = '1a000000-0000-0000-0000-000000000001'$q$
], 'MN001', 'T32 un comprobante aceptado no retrocede de estado');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO invoices (business_id, establishment_id, doc_type, series, number, environment, status,
       issue_date, customer_doc_type, customer_name, subtotal, tax_total, total, provider, requested_by, note_reason_code)
     VALUES ('b0000000-0000-0000-0000-00000000000a', 'e0000000-0000-0000-0000-00000000000a',
       '07', 'B001', 1, 'test', 'queued', current_date, 'NONE', 'Clientes varios', 2.12, 0.38, 2.50, 'fake',
       'aaaaaaaa-0000-0000-0000-000000000001', '01')$q$
], '23514', 'T33 nota de crédito sin comprobante de referencia se rechaza');

SELECT test_expect_error(ARRAY[
  $q$DELETE FROM invoices WHERE id = '1a000000-0000-0000-0000-000000000001'$q$
], 'MN001', 'T34 los comprobantes no se eliminan');

-- ---------- T35 auditoría append-only ----------
INSERT INTO audit_logs (business_id, actor_type, actor_user_id, action, entity_type, entity_id, reason)
VALUES ('b0000000-0000-0000-0000-00000000000a', 'user', 'aaaaaaaa-0000-0000-0000-000000000001', 'sale.void',
        'sale', '5a1e0000-0000-0000-0000-000000000001', 'cliente devolvió producto');
SELECT test_expect_error(ARRAY[$q$UPDATE audit_logs SET reason = 'otro'$q$], 'MN001',
  'T35 la auditoría no se puede modificar');

-- ---------- T36 Row Level Security (rol de aplicación sin privilegios de superusuario) ----------
CREATE ROLE minegocio_app_test NOLOGIN NOSUPERUSER NOBYPASSRLS;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO minegocio_app_test;
SET ROLE minegocio_app_test;

SELECT set_config('app.business_id', '', false);
SELECT test_assert((SELECT count(*) FROM sales) = 0, 'T36 sin contexto de negocio no se ve ninguna venta');

SELECT set_config('app.business_id', 'b0000000-0000-0000-0000-00000000000b', false);
SELECT test_assert((SELECT count(*) FROM sales) = 0, 'T37 el negocio B no ve las ventas del negocio A');
SELECT test_assert((SELECT count(*) FROM product_variants) = 1, 'T38 el negocio B solo ve su propio catálogo');

SELECT set_config('app.business_id', 'b0000000-0000-0000-0000-00000000000a', false);
SELECT test_assert((SELECT count(*) FROM sales) = 2, 'T39 el negocio A ve sus 2 ventas');

SELECT test_expect_error(ARRAY[
  $q$INSERT INTO customers (id, business_id, name) VALUES (gen_random_uuid(), 'b0000000-0000-0000-0000-00000000000b', 'Intruso')$q$
], '42501', 'T40 en contexto A no se puede escribir datos del negocio B');

RESET ROLE;

SELECT test_assert(true, 'FIN: todas las aserciones pasaron');
