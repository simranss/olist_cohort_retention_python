DROP TABLE IF EXISTS geolocation;
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS product_category_name_translation;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id              CHAR(32)    NOT NULL,
    customer_unique_id       CHAR(32)    NOT NULL,
    customer_zip_code_prefix CHAR(5)     NOT NULL,
    customer_city            VARCHAR(60) NOT NULL,
    customer_state           CHAR(2)     NOT NULL,
    PRIMARY KEY (customer_id)
);

CREATE TABLE orders (
    order_id                      CHAR(32)    NOT NULL,
    customer_id                   CHAR(32)    NOT NULL,
    order_status                  VARCHAR(20) NOT NULL,
    order_purchase_timestamp      DATETIME    NOT NULL,
    order_approved_at             DATETIME,
    order_delivered_carrier_date  DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME    NOT NULL,
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CHECK (order_status IN ('delivered', 'shipped', 'canceled', 'unavailable', 'invoiced', 'processing', 'created', 'approved'))
);

CREATE TABLE products (
    product_id                 CHAR(32)     NOT NULL,
    product_category_name      VARCHAR(100),
    product_name_length        INT,
    product_description_length INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT,
    PRIMARY KEY (product_id)
);

CREATE TABLE sellers (
    seller_id              CHAR(32)    NOT NULL,
    seller_zip_code_prefix CHAR(5)     NOT NULL,
    seller_city            VARCHAR(60) NOT NULL,
    seller_state           CHAR(2)     NOT NULL,
    PRIMARY KEY (seller_id)
);

CREATE TABLE product_category_name_translation (
    product_category_name         VARCHAR(100) NOT NULL,
    product_category_name_english VARCHAR(100) NOT NULL,
    PRIMARY KEY (product_category_name)
);

CREATE TABLE order_items (
    order_id                   CHAR(32)       NOT NULL,
    order_item_id              INT            NOT NULL,
    product_id                 CHAR(32)       NOT NULL,
    seller_id                  CHAR(32)       NOT NULL,
    shipping_limit_date        DATETIME       NOT NULL,
    price                      DECIMAL(10, 2) NOT NULL,
    freight_value              DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders (order_id),
    FOREIGN KEY (product_id) REFERENCES products (product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers (seller_id)
);

CREATE TABLE order_payments (
    order_id             CHAR(32)       NOT NULL,
    payment_sequential   INT            NOT NULL,
    payment_type         VARCHAR(20)    NOT NULL,
    payment_installments INT            NOT NULL,
    payment_value        DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CHECK (payment_type IN ('credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined'))
);

CREATE TABLE order_reviews (
    review_id               CHAR(32)     NOT NULL,
    order_id                CHAR(32)     NOT NULL,
    review_score            SMALLINT     NOT NULL,
    review_comment_title    VARCHAR(50),
    review_comment_message  TEXT,
    review_creation_date    DATE         NOT NULL,
    review_answer_timestamp DATETIME     NOT NULL,
    PRIMARY KEY (review_id, order_id),
    FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CHECK (review_score BETWEEN 1 AND 5)
);

-- currently, unused and without a PK. Kept so we have the data in db
CREATE TABLE geolocation(
    geolocation_zip_code_prefix CHAR(5)        NOT NULL,
    geolocation_lat             DECIMAL(10, 7) NOT NULL,
    geolocation_lng             DECIMAL(10, 7) NOT NULL,
    geolocation_city            VARCHAR(60)    NOT NULL,
    geolocation_state           CHAR(2)        NOT null
);