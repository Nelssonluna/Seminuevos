-- =====================================================================
--  Proyecto final - Fase 2: Base de datos
--  Página web de seminuevos (caso de referencia: Geely Lindavista)
--  Motor: MySQL 8.0  |  Juego de caracteres: utf8mb4
-- =====================================================================

-- No se elimina una base existente. Importar en un entorno de prueba vacío.
CREATE DATABASE seminuevos_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_spanish_ci;
USE seminuevos_db;

-- ---------------------------------------------------------------------
-- 1. ROLES: catálogo de roles con acceso a la página (Usuario, Administrador)
--    El visitante no se guarda: es cualquier persona sin sesión iniciada.
-- ---------------------------------------------------------------------
CREATE TABLE roles (
  id_rol        TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre        VARCHAR(30)      NOT NULL,
  descripcion   VARCHAR(150)     NULL,
  CONSTRAINT pk_roles PRIMARY KEY (id_rol),
  CONSTRAINT uq_roles_nombre UNIQUE (nombre)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 2. USUARIOS: cuentas registradas. Guarda el perfil (nombre, correo,
--    teléfono) que se reutiliza para llenar la solicitud de cita.
-- ---------------------------------------------------------------------
CREATE TABLE usuarios (
  id_usuario        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  id_rol            TINYINT UNSIGNED NOT NULL DEFAULT 1,
  nombre_completo   VARCHAR(100)     NOT NULL,
  correo            VARCHAR(120)     NOT NULL,
  telefono          VARCHAR(15)      NOT NULL,
  contrasena_hash   VARCHAR(255)     NOT NULL,
  activo            BOOLEAN          NOT NULL DEFAULT TRUE,
  fecha_registro    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_usuarios PRIMARY KEY (id_usuario),
  CONSTRAINT uq_usuarios_correo UNIQUE (correo),
  CONSTRAINT fk_usuarios_roles FOREIGN KEY (id_rol)
    REFERENCES roles (id_rol)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 3. MARCAS: catálogo de marcas. Alimenta el filtro "Marca" del catálogo
--    y evita que la misma marca se escriba de formas distintas.
-- ---------------------------------------------------------------------
CREATE TABLE marcas (
  id_marca   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre     VARCHAR(50)       NOT NULL,
  CONSTRAINT pk_marcas PRIMARY KEY (id_marca),
  CONSTRAINT uq_marcas_nombre UNIQUE (nombre)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 4. AUTOMOVILES: inventario de seminuevos (CRUD del administrador).
-- ---------------------------------------------------------------------
CREATE TABLE automoviles (
  id_automovil         INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  id_marca             SMALLINT UNSIGNED NOT NULL,
  modelo               VARCHAR(60)       NOT NULL,
  anio                 SMALLINT UNSIGNED NOT NULL,
  precio               DECIMAL(10,2)     NOT NULL,
  kilometraje          INT UNSIGNED      NOT NULL,
  transmision          ENUM('Automática','Manual','CVT')                         NOT NULL,
  combustible          ENUM('Gasolina','Diésel','Híbrido','Eléctrico')           NOT NULL,
  color                VARCHAR(30)       NOT NULL,
  imagen               VARCHAR(255)      NULL,
  estatus              ENUM('Disponible','Vendido') NOT NULL DEFAULT 'Disponible',
  destacado            BOOLEAN           NOT NULL DEFAULT FALSE,
  fecha_alta           DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion  DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP
                                         ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_automoviles PRIMARY KEY (id_automovil),
  CONSTRAINT fk_automoviles_marcas FOREIGN KEY (id_marca)
    REFERENCES marcas (id_marca)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_automoviles_precio CHECK (precio > 0),
  CONSTRAINT ck_automoviles_anio   CHECK (anio BETWEEN 1990 AND 2100)
) ENGINE = InnoDB;

-- Índices para los filtros del catálogo (marca, precio, año) y el buscador
CREATE INDEX ix_automoviles_filtros ON automoviles (estatus, id_marca, anio, precio);
CREATE INDEX ix_automoviles_modelo  ON automoviles (modelo);

-- ---------------------------------------------------------------------
-- 5. FAVORITOS: tabla intermedia de la relación n-n usuarios–automóviles.
--    La llave primaria compuesta impide guardar dos veces el mismo auto.
-- ---------------------------------------------------------------------
CREATE TABLE favoritos (
  id_usuario      INT UNSIGNED NOT NULL,
  id_automovil    INT UNSIGNED NOT NULL,
  fecha_agregado  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_favoritos PRIMARY KEY (id_usuario, id_automovil),
  CONSTRAINT fk_favoritos_usuarios FOREIGN KEY (id_usuario)
    REFERENCES usuarios (id_usuario)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_favoritos_automoviles FOREIGN KEY (id_automovil)
    REFERENCES automoviles (id_automovil)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 6. CITAS: solicitudes de prueba de manejo. También resuelve una relación
--    n-n entre usuarios y automóviles, pero con datos propios (fecha, hora,
--    estatus), por eso tiene su propia llave primaria.
--    contacto_*: copia de los datos del perfil al momento de solicitar.
-- ---------------------------------------------------------------------
CREATE TABLE citas (
  id_cita              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario           INT UNSIGNED NOT NULL,
  id_automovil         INT UNSIGNED NOT NULL,
  contacto_nombre      VARCHAR(100) NOT NULL,
  contacto_correo      VARCHAR(120) NOT NULL,
  contacto_telefono    VARCHAR(15)  NOT NULL,
  fecha                DATE         NOT NULL,
  hora                 TIME         NOT NULL,
  comentario           VARCHAR(255) NULL,
  estatus              ENUM('Pendiente','Confirmada','Reprogramada','Cancelada')
                                    NOT NULL DEFAULT 'Pendiente',
  fecha_solicitud      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                    ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_citas PRIMARY KEY (id_cita),
  CONSTRAINT fk_citas_usuarios FOREIGN KEY (id_usuario)
    REFERENCES usuarios (id_usuario)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_citas_automoviles FOREIGN KEY (id_automovil)
    REFERENCES automoviles (id_automovil)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE INDEX ix_citas_estatus_fecha ON citas (estatus, fecha, hora);

-- =====================================================================
--  DATOS DE PRUEBA
-- =====================================================================
INSERT INTO roles (nombre, descripcion) VALUES
  ('Usuario',       'Cliente registrado: favoritos, perfil y citas'),
  ('Administrador', 'Gestiona automóviles, citas y usuarios');

-- Las contraseñas se guardan como hashes desde el back-end (bcrypt);
-- aquí se usan valores de ejemplo.
INSERT INTO usuarios (id_rol, nombre_completo, correo, telefono, contrasena_hash) VALUES
  (2, 'Administrador Seminuevos', 'admin@seminuevos.com', '8100000000', '$2b$10$ejemploHashAdmin'),
  (1, 'Juan Pérez',               'juan@correo.com',      '8100000001', '$2b$10$ejemploHashJuan'),
  (1, 'Ana García',               'ana@correo.com',       '8111111111', '$2b$10$ejemploHashAna'),
  (1, 'Luis Torres',              'luis@correo.com',      '8122222222', '$2b$10$ejemploHashLuis');

INSERT INTO marcas (nombre) VALUES
  ('Geely'), ('Nissan'), ('Toyota'), ('Volkswagen'), ('Chevrolet');

INSERT INTO automoviles
  (id_marca, modelo, anio, precio, kilometraje, transmision, combustible, color, imagen, estatus, destacado)
VALUES
  (1, 'Coolray',  2024, 350000.00, 24000, 'Automática', 'Gasolina', 'Gris',   'img/auto1.svg', 'Disponible', TRUE),
  (2, 'Versa',    2023, 280000.00, 36000, 'Automática', 'Gasolina', 'Blanco', 'img/auto2.svg',   'Disponible', TRUE),
  (4, 'Polo',     2022, 220000.00, 45000, 'Manual',     'Gasolina', 'Rojo',   'img/auto3.svg',    'Vendido',    FALSE),
  (3, 'Corolla',  2021, 310000.00, 52000, 'CVT',        'Híbrido',  'Negro',  'img/auto2.svg', 'Disponible', TRUE),
  (5, 'Aveo',     2023, 215000.00, 30000, 'Manual',     'Gasolina', 'Azul',   'img/auto3.svg',    'Disponible', FALSE);

INSERT INTO favoritos (id_usuario, id_automovil) VALUES
  (2, 1), (2, 2), (3, 4), (4, 1);

INSERT INTO citas
  (id_usuario, id_automovil, contacto_nombre, contacto_correo, contacto_telefono, fecha, hora, comentario, estatus)
VALUES
  (2, 1, 'Juan Pérez', 'juan@correo.com', '8100000001', '2026-11-12', '16:00:00', NULL,                         'Pendiente'),
  (3, 2, 'Ana García', 'ana@correo.com',  '8111111111', '2026-11-18', '12:30:00', 'Me interesa el financiamiento', 'Confirmada');

-- =====================================================================
--  CONSULTAS DE VERIFICACIÓN (para las capturas de pantalla)
-- =====================================================================
-- SHOW TABLES;
-- DESCRIBE usuarios;  DESCRIBE automoviles;  DESCRIBE citas;
-- Catálogo público (solo unidades disponibles):
-- SELECT a.id_automovil, m.nombre AS marca, a.modelo, a.anio, a.precio, a.kilometraje
--   FROM automoviles a JOIN marcas m ON m.id_marca = a.id_marca
--  WHERE a.estatus = 'Disponible' ORDER BY a.precio;
-- Favoritos de un usuario:
-- SELECT u.nombre_completo, m.nombre, a.modelo, a.anio, f.fecha_agregado
--   FROM favoritos f JOIN usuarios u ON u.id_usuario = f.id_usuario
--   JOIN automoviles a ON a.id_automovil = f.id_automovil
--   JOIN marcas m ON m.id_marca = a.id_marca WHERE f.id_usuario = 2;
-- Gestión de citas (administrador):
-- SELECT c.id_cita, c.contacto_nombre, c.contacto_telefono,
--        CONCAT(m.nombre,' ',a.modelo,' ',a.anio) AS automovil, c.fecha, c.hora, c.estatus
--   FROM citas c JOIN automoviles a ON a.id_automovil = c.id_automovil
--   JOIN marcas m ON m.id_marca = a.id_marca ORDER BY c.fecha, c.hora;
