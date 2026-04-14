--
-- PostgreSQL database dump
--

-- Dumped from database version 14.15 (Ubuntu 14.15-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.15 (Ubuntu 14.15-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: _heroku; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA _heroku;


ALTER SCHEMA _heroku OWNER TO postgres;

--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: create_ext(); Type: FUNCTION; Schema: _heroku; Owner: postgres
--

CREATE FUNCTION _heroku.create_ext() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  databaseowner TEXT;

  r RECORD;

BEGIN

  IF tg_tag = 'CREATE EXTENSION' and current_user != 'rds_superuser' THEN
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        CONTINUE WHEN r.command_tag != 'CREATE EXTENSION' OR r.object_type != 'extension';

        schemaname = (
            SELECT n.nspname
            FROM pg_catalog.pg_extension AS e
            INNER JOIN pg_catalog.pg_namespace AS n
            ON e.extnamespace = n.oid
            WHERE e.oid = r.objid
        );

        databaseowner = (
            SELECT pg_catalog.pg_get_userbyid(d.datdba)
            FROM pg_catalog.pg_database d
            WHERE d.datname = current_database()
        );
        --RAISE NOTICE 'Record for event trigger %, objid: %,tag: %, current_user: %, schema: %, database_owenr: %', r.object_identity, r.objid, tg_tag, current_user, schemaname, databaseowner;
        IF r.object_identity = 'address_standardizer_data_us' THEN
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'us_gaz');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'us_lex');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'us_rules');
        ELSIF r.object_identity = 'amcheck' THEN
            EXECUTE format('GRANT EXECUTE ON FUNCTION %I.bt_index_check TO %I;', schemaname, databaseowner);
            EXECUTE format('GRANT EXECUTE ON FUNCTION %I.bt_index_parent_check TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'dict_int' THEN
            EXECUTE format('ALTER TEXT SEARCH DICTIONARY %I.intdict OWNER TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'pg_partman' THEN
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'part_config');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'part_config_sub');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'custom_time_partitions');
        ELSIF r.object_identity = 'pg_stat_statements' THEN
            EXECUTE format('GRANT EXECUTE ON FUNCTION %I.pg_stat_statements_reset TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'postgis' THEN
            PERFORM _heroku.postgis_after_create();
        ELSIF r.object_identity = 'postgis_raster' THEN
            PERFORM _heroku.postgis_after_create();
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT', databaseowner, 'raster_columns');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT', databaseowner, 'raster_overviews');
        ELSIF r.object_identity = 'postgis_topology' THEN
            PERFORM _heroku.postgis_after_create();
            EXECUTE format('GRANT USAGE ON SCHEMA topology TO %I;', databaseowner);
            EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA topology TO %I;', databaseowner);
            PERFORM _heroku.grant_table_if_exists('topology', 'SELECT, UPDATE, INSERT, DELETE', databaseowner);
            EXECUTE format('GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA topology TO %I;', databaseowner);
        ELSIF r.object_identity = 'postgis_tiger_geocoder' THEN
            PERFORM _heroku.postgis_after_create();
            EXECUTE format('GRANT USAGE ON SCHEMA tiger TO %I;', databaseowner);
            EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA tiger TO %I;', databaseowner);
            PERFORM _heroku.grant_table_if_exists('tiger', 'SELECT, UPDATE, INSERT, DELETE', databaseowner);

            EXECUTE format('GRANT USAGE ON SCHEMA tiger_data TO %I;', databaseowner);
            EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA tiger_data TO %I;', databaseowner);
            PERFORM _heroku.grant_table_if_exists('tiger_data', 'SELECT, UPDATE, INSERT, DELETE', databaseowner);
        END IF;
    END LOOP;
  END IF;
END;
$$;


ALTER FUNCTION _heroku.create_ext() OWNER TO postgres;

--
-- Name: drop_ext(); Type: FUNCTION; Schema: _heroku; Owner: postgres
--

CREATE FUNCTION _heroku.drop_ext() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  databaseowner TEXT;

  r RECORD;

BEGIN

  IF tg_tag = 'DROP EXTENSION' and current_user != 'rds_superuser' THEN
    FOR r IN SELECT * FROM pg_event_trigger_dropped_objects()
    LOOP
      CONTINUE WHEN r.object_type != 'extension';

      databaseowner = (
            SELECT pg_catalog.pg_get_userbyid(d.datdba)
            FROM pg_catalog.pg_database d
            WHERE d.datname = current_database()
      );

      --RAISE NOTICE 'Record for event trigger %, objid: %,tag: %, current_user: %, database_owner: %, schemaname: %', r.object_identity, r.objid, tg_tag, current_user, databaseowner, r.schema_name;

      IF r.object_identity = 'postgis_topology' THEN
          EXECUTE format('DROP SCHEMA IF EXISTS topology');
      END IF;
    END LOOP;

  END IF;
END;
$$;


ALTER FUNCTION _heroku.drop_ext() OWNER TO postgres;

--
-- Name: extension_before_drop(); Type: FUNCTION; Schema: _heroku; Owner: postgres
--

CREATE FUNCTION _heroku.extension_before_drop() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  query TEXT;

BEGIN
  query = (SELECT current_query());

  -- RAISE NOTICE 'executing extension_before_drop: tg_event: %, tg_tag: %, current_user: %, session_user: %, query: %', tg_event, tg_tag, current_user, session_user, query;
  IF tg_tag = 'DROP EXTENSION' and not pg_has_role(session_user, 'rds_superuser', 'MEMBER') THEN
    -- DROP EXTENSION [ IF EXISTS ] name [, ...] [ CASCADE | RESTRICT ]
    IF (regexp_match(query, 'DROP\s+EXTENSION\s+(IF\s+EXISTS)?.*(plpgsql)', 'i') IS NOT NULL) THEN
      RAISE EXCEPTION 'The plpgsql extension is required for database management and cannot be dropped.';
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION _heroku.extension_before_drop() OWNER TO postgres;

--
-- Name: grant_table_if_exists(text, text, text, text); Type: FUNCTION; Schema: _heroku; Owner: postgres
--

CREATE FUNCTION _heroku.grant_table_if_exists(alias_schemaname text, grants text, databaseowner text, alias_tablename text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

BEGIN

  IF alias_tablename IS NULL THEN
    EXECUTE format('GRANT %s ON ALL TABLES IN SCHEMA %I TO %I;', grants, alias_schemaname, databaseowner);
  ELSE
    IF EXISTS (SELECT 1 FROM pg_tables WHERE pg_tables.schemaname = alias_schemaname AND pg_tables.tablename = alias_tablename) THEN
      EXECUTE format('GRANT %s ON TABLE %I.%I TO %I;', grants, alias_schemaname, alias_tablename, databaseowner);
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION _heroku.grant_table_if_exists(alias_schemaname text, grants text, databaseowner text, alias_tablename text) OWNER TO postgres;

--
-- Name: postgis_after_create(); Type: FUNCTION; Schema: _heroku; Owner: postgres
--

CREATE FUNCTION _heroku.postgis_after_create() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    schemaname TEXT;
    databaseowner TEXT;
BEGIN
    schemaname = (
        SELECT n.nspname
        FROM pg_catalog.pg_extension AS e
        INNER JOIN pg_catalog.pg_namespace AS n ON e.extnamespace = n.oid
        WHERE e.extname = 'postgis'
    );
    databaseowner = (
        SELECT pg_catalog.pg_get_userbyid(d.datdba)
        FROM pg_catalog.pg_database d
        WHERE d.datname = current_database()
    );

    EXECUTE format('GRANT EXECUTE ON FUNCTION %I.st_tileenvelope TO %I;', schemaname, databaseowner);
    EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE %I.spatial_ref_sys TO %I;', schemaname, databaseowner);
END;
$$;


ALTER FUNCTION _heroku.postgis_after_create() OWNER TO postgres;

--
-- Name: validate_extension(); Type: FUNCTION; Schema: _heroku; Owner: postgres
--

CREATE FUNCTION _heroku.validate_extension() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  r RECORD;

BEGIN

  IF tg_tag = 'CREATE EXTENSION' and current_user != 'rds_superuser' THEN
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
      CONTINUE WHEN r.command_tag != 'CREATE EXTENSION' OR r.object_type != 'extension';

      schemaname = (
        SELECT n.nspname
        FROM pg_catalog.pg_extension AS e
        INNER JOIN pg_catalog.pg_namespace AS n
        ON e.extnamespace = n.oid
        WHERE e.oid = r.objid
      );

      IF schemaname = '_heroku' THEN
        RAISE EXCEPTION 'Creating extensions in the _heroku schema is not allowed';
      END IF;
    END LOOP;
  END IF;
END;
$$;


ALTER FUNCTION _heroku.validate_extension() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_attendance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_attendance (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    role character varying(50) NOT NULL,
    date date NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    fine bigint,
    day character varying(10),
    is_deleted boolean NOT NULL,
    is_paid boolean NOT NULL,
    "timestamp" timestamp with time zone
);


ALTER TABLE public.app_attendance OWNER TO postgres;

--
-- Name: app_attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.app_attendance ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.app_attendance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: app_finepayment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_finepayment (
    id bigint NOT NULL,
    payer_name character varying(255) NOT NULL,
    payer_email character varying(254) NOT NULL,
    amount integer NOT NULL,
    cardholder_name character varying(255) NOT NULL,
    payment_intent_id character varying(255) NOT NULL,
    payment_date date NOT NULL,
    attendance_id integer NOT NULL
);


ALTER TABLE public.app_finepayment OWNER TO postgres;

--
-- Name: app_finepayment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.app_finepayment ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.app_finepayment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_group (
    id bigint NOT NULL,
    name character varying(150) NOT NULL
);


ALTER TABLE public.auth_group OWNER TO postgres;

--
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_group_permissions (
    id bigint NOT NULL,
    group_id bigint NOT NULL,
    permission_id bigint NOT NULL
);


ALTER TABLE public.auth_group_permissions OWNER TO postgres;

--
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_permission (
    id bigint NOT NULL,
    content_type_id bigint NOT NULL,
    codename character varying(100) NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.auth_permission OWNER TO postgres;

--
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_permission_id_seq OWNER TO postgres;

--
-- Name: auth_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_permission_id_seq OWNED BY public.auth_permission.id;


--
-- Name: auth_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_user_id_seq OWNER TO postgres;

--
-- Name: auth_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user (
    id bigint DEFAULT nextval('public.auth_user_id_seq'::regclass) NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp without time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp without time zone NOT NULL,
    first_name character varying(150) NOT NULL
);


ALTER TABLE public.auth_user OWNER TO postgres;

--
-- Name: auth_user_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user_groups (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    group_id bigint NOT NULL
);


ALTER TABLE public.auth_user_groups OWNER TO postgres;

--
-- Name: auth_user_user_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user_user_permissions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    permission_id bigint NOT NULL
);


ALTER TABLE public.auth_user_user_permissions OWNER TO postgres;

--
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_admin_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_admin_log_id_seq OWNER TO postgres;

--
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_admin_log (
    id bigint DEFAULT nextval('public.django_admin_log_id_seq'::regclass) NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag character varying(255) NOT NULL,
    change_message text NOT NULL,
    content_type_id bigint,
    user_id bigint NOT NULL,
    action_time timestamp without time zone NOT NULL
);


ALTER TABLE public.django_admin_log OWNER TO postgres;

--
-- Name: django_celery_beat_clockedschedule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_celery_beat_clockedschedule (
    id integer NOT NULL,
    clocked_time timestamp with time zone NOT NULL
);


ALTER TABLE public.django_celery_beat_clockedschedule OWNER TO postgres;

--
-- Name: django_celery_beat_clockedschedule_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.django_celery_beat_clockedschedule ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_celery_beat_clockedschedule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_celery_beat_crontabschedule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_celery_beat_crontabschedule (
    id integer NOT NULL,
    minute character varying(240) NOT NULL,
    hour character varying(96) NOT NULL,
    day_of_week character varying(64) NOT NULL,
    day_of_month character varying(124) NOT NULL,
    month_of_year character varying(64) NOT NULL,
    timezone character varying(63) NOT NULL
);


ALTER TABLE public.django_celery_beat_crontabschedule OWNER TO postgres;

--
-- Name: django_celery_beat_crontabschedule_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.django_celery_beat_crontabschedule ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_celery_beat_crontabschedule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_celery_beat_intervalschedule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_celery_beat_intervalschedule (
    id integer NOT NULL,
    every integer NOT NULL,
    period character varying(24) NOT NULL
);


ALTER TABLE public.django_celery_beat_intervalschedule OWNER TO postgres;

--
-- Name: django_celery_beat_intervalschedule_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.django_celery_beat_intervalschedule ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_celery_beat_intervalschedule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_celery_beat_periodictask; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_celery_beat_periodictask (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    task character varying(200) NOT NULL,
    args text NOT NULL,
    kwargs text NOT NULL,
    queue character varying(200),
    exchange character varying(200),
    routing_key character varying(200),
    expires timestamp with time zone,
    enabled boolean NOT NULL,
    last_run_at timestamp with time zone,
    total_run_count integer NOT NULL,
    date_changed timestamp with time zone NOT NULL,
    description text NOT NULL,
    crontab_id integer,
    interval_id integer,
    solar_id integer,
    one_off boolean NOT NULL,
    start_time timestamp with time zone,
    priority integer,
    headers text NOT NULL,
    clocked_id integer,
    expire_seconds integer,
    CONSTRAINT django_celery_beat_periodictask_expire_seconds_check CHECK ((expire_seconds >= 0)),
    CONSTRAINT django_celery_beat_periodictask_priority_check CHECK ((priority >= 0)),
    CONSTRAINT django_celery_beat_periodictask_total_run_count_check CHECK ((total_run_count >= 0))
);


ALTER TABLE public.django_celery_beat_periodictask OWNER TO postgres;

--
-- Name: django_celery_beat_periodictask_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.django_celery_beat_periodictask ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_celery_beat_periodictask_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_celery_beat_periodictasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_celery_beat_periodictasks (
    ident smallint NOT NULL,
    last_update timestamp with time zone NOT NULL
);


ALTER TABLE public.django_celery_beat_periodictasks OWNER TO postgres;

--
-- Name: django_celery_beat_solarschedule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_celery_beat_solarschedule (
    id integer NOT NULL,
    event character varying(24) NOT NULL,
    latitude numeric(9,6) NOT NULL,
    longitude numeric(9,6) NOT NULL
);


ALTER TABLE public.django_celery_beat_solarschedule OWNER TO postgres;

--
-- Name: django_celery_beat_solarschedule_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.django_celery_beat_solarschedule ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_celery_beat_solarschedule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_celery_results_chordcounter; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_celery_results_chordcounter (
    id integer NOT NULL,
    group_id character varying(255) NOT NULL,
    sub_tasks text NOT NULL,
    count integer NOT NULL,
    CONSTRAINT django_celery_results_chordcounter_count_check CHECK ((count >= 0))
);


ALTER TABLE public.django_celery_results_chordcounter OWNER TO postgres;

--
-- Name: django_celery_results_chordcounter_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.django_celery_results_chordcounter ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_celery_results_chordcounter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_celery_results_groupresult; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_celery_results_groupresult (
    id integer NOT NULL,
    group_id character varying(255) NOT NULL,
    date_created timestamp with time zone NOT NULL,
    date_done timestamp with time zone NOT NULL,
    content_type character varying(128) NOT NULL,
    content_encoding character varying(64) NOT NULL,
    result text
);


ALTER TABLE public.django_celery_results_groupresult OWNER TO postgres;

--
-- Name: django_celery_results_groupresult_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.django_celery_results_groupresult ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_celery_results_groupresult_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_celery_results_taskresult; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_celery_results_taskresult (
    id integer NOT NULL,
    task_id character varying(255) NOT NULL,
    status character varying(50) NOT NULL,
    content_type character varying(128) NOT NULL,
    content_encoding character varying(64) NOT NULL,
    result text,
    date_done timestamp with time zone NOT NULL,
    traceback text,
    meta text,
    task_args text,
    task_kwargs text,
    task_name character varying(255),
    worker character varying(100),
    date_created timestamp with time zone NOT NULL,
    periodic_task_name character varying(255)
);


ALTER TABLE public.django_celery_results_taskresult OWNER TO postgres;

--
-- Name: django_celery_results_taskresult_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.django_celery_results_taskresult ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_celery_results_taskresult_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_content_type (
    id bigint NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


ALTER TABLE public.django_content_type OWNER TO postgres;

--
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_content_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_content_type_id_seq OWNER TO postgres;

--
-- Name: django_content_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_content_type_id_seq OWNED BY public.django_content_type.id;


--
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp without time zone NOT NULL
);


ALTER TABLE public.django_migrations OWNER TO postgres;

--
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_migrations_id_seq OWNER TO postgres;

--
-- Name: django_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_migrations_id_seq OWNED BY public.django_migrations.id;


--
-- Name: django_session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp without time zone NOT NULL
);


ALTER TABLE public.django_session OWNER TO postgres;

--
-- Name: auth_permission id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission ALTER COLUMN id SET DEFAULT nextval('public.auth_permission_id_seq'::regclass);


--
-- Name: django_content_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_content_type ALTER COLUMN id SET DEFAULT nextval('public.django_content_type_id_seq'::regclass);


--
-- Name: django_migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_migrations ALTER COLUMN id SET DEFAULT nextval('public.django_migrations_id_seq'::regclass);


--
-- Data for Name: app_attendance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_attendance (id, name, role, date, created_at, updated_at, fine, day, is_deleted, is_paid, "timestamp") FROM stdin;
69	Jeff Bezos	Student	2024-12-25	2024-12-24 19:35:37	2024-12-28 20:00:41	500	Wednesday	f	t	\N
103	Saad Akhtar	Teacher	2024-12-27	2024-12-28 19:20:10	2024-12-28 19:46:05	500	Friday	f	t	\N
88	Sami Ullah Khan	Student	2024-12-28	2024-12-28 19:10:43	2024-12-28 19:36:45	500	Saturday	f	t	\N
68	Bill Gates	Student	2024-12-25	2024-12-24 19:35:37	2024-12-28 19:57:49	500	Wednesday	f	t	\N
65	Bill Gates	Student	2024-12-21	2024-12-21 17:41:32	2024-12-22 09:43:31	500	Saturday	f	t	\N
71	Abdullah Shahid	Teacher	2024-12-25	2024-12-24 19:35:37	2024-12-28 19:59:35	500	Wednesday	f	t	\N
96	Sami Ullah Khan	Student	2024-12-27	2024-12-28 19:20:10	2024-12-28 19:20:10	500	Friday	f	f	\N
66	Jeff Bezos	Student	2024-12-21	2024-12-21 17:41:32	2024-12-21 17:41:32	500	Saturday	f	f	\N
99	Elon Musk	Student	2024-12-27	2024-12-28 19:20:10	2024-12-28 19:20:10	500	Friday	f	f	\N
86	Hamid Mir	Student	2024-12-23	2024-12-24 19:53:59	2024-12-24 19:53:59	500	Monday	f	f	\N
102	Athar Mehboob	Student	2024-12-27	2024-12-28 19:20:10	2024-12-28 19:20:10	500	Friday	f	f	\N
83	Jeff Bezos	Student	2024-12-23	2024-12-24 19:53:59	2024-12-24 19:53:59	500	Monday	f	f	\N
84	Elon Musk	Student	2024-12-23	2024-12-24 19:53:59	2024-12-24 19:53:59	500	Monday	f	f	\N
100	Abdullah Shahid	Teacher	2024-12-27	2024-12-28 19:20:10	2024-12-28 19:20:10	500	Friday	f	f	\N
109	Hamid Mir	Student	2024-12-26	2024-12-28 19:21:19	2024-12-29 19:24:14.083003	500	Thursday	f	f	\N
105	Bill Gates	Student	2024-12-26	2024-12-28 19:21:19	2024-12-28 19:48:31	500	Thursday	f	t	\N
101	Hamid Mir	Student	2024-12-27	2024-12-28 19:20:10	2024-12-28 19:44:08	500	Friday	f	t	\N
76	Jeff Bezos	Student	2024-12-24	2024-12-24 19:51:13	2024-12-24 19:52:14	0	Tuesday	f	t	2024-12-24 16:45:12.812942+00
60	Saad Akhtar	Teacher	2024-12-21	2024-12-21 15:07:40	2024-12-21 15:11:13	0	Saturday	f	t	2024-12-21 19:57:03.093422+00
94	Athar Mehboob	Student	2024-12-28	2024-12-28 19:10:43	2024-12-28 19:35:19	0	Saturday	f	t	2024-12-28 23:26:10.075022+00
93	Hamid Mir	Student	2024-12-28	2024-12-28 19:10:43	2024-12-28 19:35:19	0	Saturday	f	t	2024-12-28 23:26:01.29118+00
89	Bill Gates	Student	2024-12-28	2024-12-28 19:10:43	2024-12-28 19:19:18	0	Saturday	f	t	2024-12-28 22:36:19.913233+00
67	Saad Akhtar	Teacher	2024-12-25	2024-12-24 19:35:37	2024-12-28 19:22:11	0	Wednesday	f	t	2024-12-25 13:22:02.982448+00
77	Elon Musk	Student	2024-12-24	2024-12-24 19:51:13	2024-12-24 19:52:14	0	Tuesday	f	t	2024-12-24 15:44:55.091516+00
62	Abdullah Shahid	Teacher	2024-12-21	2024-12-21 15:07:40	2024-12-21 16:03:56	0	Saturday	f	t	2024-12-21 16:57:18.703616+00
78	Abdullah Shahid	Teacher	2024-12-24	2024-12-24 19:51:13	2024-12-24 19:52:14	0	Tuesday	f	t	2024-12-24 16:43:43.52134+00
63	Hamid Mir	Student	2024-12-21	2024-12-21 15:07:40	2024-12-21 16:03:56	0	Saturday	f	t	2024-12-21 16:56:34.984975+00
64	Athar Mehboob	Student	2024-12-21	2024-12-21 15:07:40	2024-12-21 15:11:13	0	Saturday	f	t	2024-12-21 19:59:03.093422+00
91	Elon Musk	Student	2024-12-28	2024-12-28 19:10:43	2024-12-28 19:35:19	0	Saturday	f	t	2024-12-28 23:25:45.625245+00
74	Saad Akhtar	Teacher	2024-12-24	2024-12-24 19:51:13	2024-12-24 19:52:14	0	Tuesday	f	t	2024-12-24 15:41:56.284032+00
80	Athar Mehboob	Student	2024-12-24	2024-12-24 19:51:13	2024-12-24 19:52:14	0	Tuesday	f	t	2024-12-24 15:44:37.238747+00
59	Elon Musk	Student	2024-12-21	2024-12-21 15:07:40	2024-12-21 16:03:56	0	Saturday	f	t	2024-12-21 16:56:19.871294+00
95	Saad Akhtar	Teacher	2024-12-28	2024-12-28 19:10:43	2024-12-28 19:19:18	0	Saturday	f	t	2024-12-28 22:36:06.899952+00
92	Abdullah Shahid	Teacher	2024-12-28	2024-12-28 19:10:43	2024-12-28 19:19:18	0	Saturday	f	t	2024-12-28 23:06:07.704399+00
90	Jeff Bezos	Student	2024-12-28	2024-12-28 19:10:43	2024-12-28 19:35:19	0	Saturday	f	t	2024-12-28 23:26:20.482757+00
12	Bill Gates	Student	2024-12-30	2024-12-30 23:56:57.722448	2024-12-30 23:56:57.724278	500	Monday	f	f	\N
15	Abdullah Shahid	Teacher	2024-12-30	2024-12-30 23:56:57.737872	2024-12-31 20:41:33.060552	500	Monday	f	t	\N
28	Bill Gates	Student	2025-01-01	2025-01-01 00:30:59.596817	2025-01-08 00:19:17.924827	500	Wednesday	f	t	\N
26	Saad Akhtar	Teacher	2024-12-31	2024-12-31 02:03:05.659046	2024-12-31 23:29:58.848015	0	Tuesday	f	t	2024-12-31 06:58:20.738224+00
85	Abdullah Shahid	Teacher	2024-12-23	2024-12-24 19:53:59	2024-12-30 04:38:51.389495	500	Monday	f	t	\N
87	Athar Mehboob	Student	2024-12-23	2024-12-24 19:53:59	2024-12-30 14:20:40.772379	500	Monday	f	t	\N
18	Saad Akhtar	Teacher	2024-12-30	2024-12-30 23:56:57.752401	2024-12-31 02:09:39.977838	0	Monday	f	t	2024-12-30 09:26:54.13972+00
82	Bill Gates	Student	2024-12-23	2024-12-24 19:53:59	2025-01-08 18:45:30.434494	500	Monday	f	t	\N
13	Jeff Bezos	Student	2024-12-30	2024-12-30 23:56:57.727754	2024-12-31 11:43:00.676125	500	Monday	f	t	\N
16	Hamid Mir	Student	2024-12-30	2024-12-30 23:56:57.742712	2024-12-30 23:59:17.595784	0	Monday	f	t	2024-12-30 18:51:10.066312+00
25	Athar Mehboob	Student	2024-12-31	2024-12-31 02:03:04.967596	2024-12-31 23:30:00.23799	0	Tuesday	f	t	2024-12-31 13:43:25.158514+00
27	Sami Ullah Khan	Student	2025-01-01	2025-01-01 00:30:58.899893	2025-01-01 22:11:30.612706	0	Wednesday	f	t	2025-01-01 08:25:27.46607+00
20	Bill Gates	Student	2024-12-31	2024-12-31 02:03:01.554283	2024-12-31 23:29:59.787686	0	Tuesday	f	t	2024-12-31 13:43:19.941617+00
19	Sami Ullah Khan	Student	2024-12-31	2024-12-31 02:03:00.8702	2024-12-31 23:30:01.185515	0	Tuesday	f	t	2024-12-31 13:48:49.43133+00
17	Athar Mehboob	Student	2024-12-30	2024-12-30 23:56:57.747582	2025-01-08 15:26:57.495356	500	Monday	f	t	\N
23	Abdullah Shahid	Teacher	2024-12-31	2024-12-31 02:03:03.60327	2024-12-31 23:30:00.703957	0	Tuesday	f	t	2024-12-31 13:43:44.402142+00
22	Elon Musk	Student	2024-12-31	2024-12-31 02:03:02.920625	2024-12-31 23:29:59.322834	0	Tuesday	f	t	2024-12-31 13:43:13.745927+00
11	Sami Ullah Khan	Student	2024-12-30	2024-12-30 23:56:57.714928	2024-12-31 02:09:39.518299	0	Monday	f	t	2024-12-30 09:26:49.135924+00
81	Saad Akhtar	Teacher	2024-12-23	2024-12-24 19:53:59	2025-01-05 16:31:54.769004	500	Monday	f	t	\N
108	Abdullah Shahid	Teacher	2024-12-26	2024-12-28 19:21:19	2025-01-08 12:59:00.99855	500	Thursday	f	t	\N
110	Athar Mehboob	Student	2024-12-26	2024-12-28 19:21:20	2025-01-07 00:14:30.032878	500	Thursday	f	t	\N
21	Jeff Bezos	Student	2024-12-31	2024-12-31 02:03:02.239375	2025-01-01 13:29:07.094391	500	Tuesday	f	t	\N
111	Saad Akhtar	Teacher	2024-12-26	2024-12-28 19:21:20	2025-01-05 16:32:18.585831	500	Thursday	f	t	\N
29	Jeff Bezos	Student	2025-01-01	2025-01-01 00:31:00.29967	2025-01-06 11:58:52.166345	500	Wednesday	f	t	\N
107	Elon Musk	Student	2024-12-26	2024-12-28 19:21:19	2025-01-07 00:36:44.420055	500	Thursday	f	t	\N
72	Hamid Mir	Student	2024-12-25	2024-12-24 19:35:37	2025-01-07 00:37:53.804152	500	Wednesday	f	t	\N
106	Jeff Bezos	Student	2024-12-26	2024-12-28 19:21:19	2025-01-07 00:48:53.874914	500	Thursday	f	t	\N
97	Bill Gates	Student	2024-12-27	2024-12-28 19:20:10	2025-01-07 00:53:48.617243	500	Friday	f	t	\N
73	Athar Mehboob	Student	2024-12-25	2024-12-24 19:35:37	2025-01-07 11:48:37.200755	500	Wednesday	f	t	\N
98	Jeff Bezos	Student	2024-12-27	2024-12-28 19:20:10	2025-01-07 13:20:22.848627	500	Friday	f	t	\N
14	Elon Musk	Student	2024-12-30	2024-12-30 23:56:57.732847	2025-01-08 00:12:54.163857	500	Monday	f	t	\N
70	Elon Musk	Student	2024-12-25	2024-12-24 19:35:37	2025-01-08 13:01:16.253391	500	Wednesday	f	t	\N
75	Bill Gates	Student	2024-12-24	2024-12-24 19:51:13	2025-01-08 13:04:30.707833	500	Tuesday	f	t	\N
79	Hamid Mir	Student	2024-12-24	2024-12-24 19:51:13	2025-01-08 13:05:19.754087	500	Tuesday	f	t	\N
24	Hamid Mir	Student	2024-12-31	2024-12-31 02:03:04.284063	2025-01-08 15:23:55.787265	500	Tuesday	f	t	\N
30	Elon Musk	Student	2025-01-01	2025-01-01 00:31:00.991626	2025-01-01 00:31:01.220531	500	Wednesday	f	f	\N
31	Abdullah Shahid	Teacher	2025-01-01	2025-01-01 00:31:01.683699	2025-01-01 00:31:01.912853	500	Wednesday	f	f	\N
32	Hamid Mir	Student	2025-01-01	2025-01-01 00:31:02.371228	2025-01-01 00:31:02.602262	500	Wednesday	f	f	\N
34	Saad Akhtar	Teacher	2025-01-01	2025-01-01 00:31:03.776125	2025-01-01 01:08:14.473649	0	Wednesday	f	t	2024-12-31 19:59:13.639584+00
33	Athar Mehboob	Student	2025-01-01	2025-01-01 00:31:03.073433	2025-01-02 00:45:08.009778	500	Wednesday	f	t	\N
120	Hamid Mir	Student	2025-01-06	2025-01-06 00:28:17.437149	2025-01-06 00:28:17.662916	500	Monday	f	f	\N
141	Muhammad Ali	Student	2025-01-08	2025-01-08 00:05:00.276509	2025-01-08 22:20:07.86316	0	Wednesday	f	t	2025-01-08 17:18:52.287805+00
121	Abdullah Shahid	Teacher	2025-01-06	2025-01-06 00:28:18.103263	2025-01-06 00:28:18.323485	500	Monday	f	f	\N
42	Saad Akhtar	Teacher	2025-01-02	2025-01-02 00:48:00.226804	2025-01-02 01:33:53.414049	0	Thursday	f	t	2025-01-01 20:28:01.719528+00
35	Sami Ullah Khan	Student	2025-01-02	2025-01-02 00:47:55.399172	2025-01-02 13:08:55.69571	0	Thursday	f	t	2025-01-02 08:07:31.185263+00
38	Elon Musk	Student	2025-01-02	2025-01-02 00:47:57.470525	2025-01-02 13:08:55.699885	0	Thursday	f	t	2025-01-02 08:07:59.176877+00
39	Abdullah Shahid	Teacher	2025-01-02	2025-01-02 00:47:58.151783	2025-01-02 20:29:00.559742	0	Thursday	f	t	2025-01-02 15:27:36.460816+00
37	Jeff Bezos	Student	2025-01-02	2025-01-02 00:47:56.777976	2025-01-02 20:29:00.625728	0	Thursday	f	t	2025-01-02 15:28:01.59952+00
1	Sami Ullah Khan	Student	2025-01-03	2025-01-03 00:05:00.092608	2025-01-03 00:05:00.137366	500	Friday	f	f	\N
140	Athar Mehboob	Student	2025-01-08	2025-01-08 00:05:00.251599	2025-01-08 00:05:00.264042	500	Wednesday	f	f	\N
4	Elon Musk	Student	2025-01-03	2025-01-03 00:05:00.186554	2025-01-03 00:05:00.190268	500	Friday	f	f	\N
5	Abdullah Shahid	Teacher	2025-01-03	2025-01-03 00:05:00.195788	2025-01-03 00:05:00.206392	500	Friday	f	f	\N
6	Hamid Mir	Student	2025-01-03	2025-01-03 00:05:00.215323	2025-01-03 00:05:00.219831	500	Friday	f	f	\N
122	Athar Mehboob	Student	2025-01-06	2025-01-06 00:28:18.775566	2025-01-06 00:28:18.999829	500	Monday	f	f	\N
9	Sami Ullah Khan	Student	2025-01-04	2025-01-04 00:05:00.09075	2025-01-04 00:05:00.113533	500	Saturday	f	f	\N
10	Bill Gates	Student	2025-01-04	2025-01-04 00:05:00.130064	2025-01-04 00:05:00.141332	500	Saturday	f	f	\N
125	Elon Musk	Student	2025-01-06	2025-01-06 00:28:20.793296	2025-01-07 00:19:57.29341	500	Monday	f	t	\N
40	Hamid Mir	Student	2025-01-02	2025-01-02 00:47:58.847068	2025-01-07 00:43:02.209884	500	Thursday	f	t	\N
117	Saad Akhtar	Teacher	2025-01-04	2025-01-04 02:32:16.24296	2025-01-04 03:18:53.11157	0	Saturday	f	t	2025-01-03 21:40:29.038508+00
112	Jeff Bezos	Student	2025-01-04	2025-01-04 02:32:12.753359	2025-01-04 03:18:53.127492	0	Saturday	f	t	2025-01-03 21:41:50.654555+00
116	Athar Mehboob	Student	2025-01-04	2025-01-04 02:32:15.533969	2025-01-04 03:18:53.136025	0	Saturday	f	t	2025-01-03 21:42:38.168488+00
115	Hamid Mir	Student	2025-01-04	2025-01-04 02:32:14.848801	2025-01-04 03:18:53.14099	0	Saturday	f	t	2025-01-03 21:42:45.522496+00
114	Abdullah Shahid	Teacher	2025-01-04	2025-01-04 02:32:14.154912	2025-01-04 03:25:54.519915	0	Saturday	f	t	2025-01-03 22:25:47.088921+00
124	Bill Gates	Student	2025-01-06	2025-01-06 00:28:20.112172	2025-01-06 00:28:20.333661	500	Monday	f	f	\N
7	Athar Mehboob	Student	2025-01-03	2025-01-03 00:05:00.226741	2025-01-05 16:12:13.993633	500	Friday	f	t	\N
8	Saad Akhtar	Teacher	2025-01-03	2025-01-03 00:05:00.243606	2025-01-05 16:32:45.745414	500	Friday	f	t	\N
41	Athar Mehboob	Student	2025-01-02	2025-01-02 00:47:59.543533	2025-01-05 19:29:21.03298	500	Thursday	f	t	\N
135	Saad Akhtar	Teacher	2025-01-07	2025-01-07 00:05:00.263122	2025-01-07 00:45:53.274955	0	Tuesday	f	t	2025-01-06 19:43:47.070948+00
126	Saad Akhtar	Teacher	2025-01-06	2025-01-06 00:28:21.458984	2025-01-06 01:27:21.222224	0	Monday	f	t	2025-01-05 20:26:37.891634+00
123	Muhammad Ali	Student	2025-01-06	2025-01-06 00:28:19.450821	2025-01-06 01:27:21.466018	0	Monday	f	t	2025-01-05 20:26:42.290826+00
113	Elon Musk	Student	2025-01-04	2025-01-04 02:32:13.456958	2025-01-06 11:52:23.498085	500	Saturday	f	t	\N
2	Bill Gates	Student	2025-01-03	2025-01-03 00:05:00.14633	2025-01-06 23:26:00.642824	500	Friday	f	t	\N
36	Bill Gates	Student	2025-01-02	2025-01-02 00:47:56.09209	2025-01-06 23:33:33.396445	500	Thursday	f	t	\N
127	Sami Ullah Khan	Student	2025-01-07	2025-01-07 00:05:00.150118	2025-01-07 00:05:00.169726	500	Tuesday	f	f	\N
118	Sami Ullah Khan	Student	2025-01-06	2025-01-06 00:28:16.102068	2025-01-06 00:28:16.327289	500	Monday	f	f	\N
119	Jeff Bezos	Student	2025-01-06	2025-01-06 00:28:16.757596	2025-01-06 00:28:16.992571	500	Monday	f	f	\N
130	Abdullah Shahid	Teacher	2025-01-07	2025-01-07 00:05:00.220977	2025-01-07 00:05:00.22744	500	Tuesday	f	f	\N
142	Bill Gates	Student	2025-01-08	2025-01-08 00:05:00.294171	2025-01-08 00:05:00.299849	500	Wednesday	f	f	\N
147	Hamid Mir	Student	2025-01-09	2025-01-09 00:05:00.358882	2025-01-09 00:05:00.360729	500	Thursday	f	f	\N
134	Elon Musk	Student	2025-01-07	2025-01-07 00:05:00.256817	2025-01-07 00:05:00.259342	500	Tuesday	f	f	\N
132	Muhammad Ali	Student	2025-01-07	2025-01-07 00:05:00.239006	2025-01-07 00:45:53.73479	0	Tuesday	f	t	2025-01-06 19:44:36.241952+00
128	Jeff Bezos	Student	2025-01-07	2025-01-07 00:05:00.195269	2025-01-07 00:45:54.183676	0	Tuesday	f	t	2025-01-06 19:44:57.252574+00
131	Athar Mehboob	Student	2025-01-07	2025-01-07 00:05:00.231577	2025-01-07 00:45:54.63255	0	Tuesday	f	t	2025-01-06 19:45:00.157216+00
129	Hamid Mir	Student	2025-01-07	2025-01-07 00:05:00.20629	2025-01-07 00:45:55.07995	0	Tuesday	f	t	2025-01-06 19:45:04.84231+00
133	Bill Gates	Student	2025-01-07	2025-01-07 00:05:00.248063	2025-01-07 00:45:55.530918	0	Tuesday	f	t	2025-01-06 19:45:07.290274+00
3	Jeff Bezos	Student	2025-01-03	2025-01-03 00:05:00.1721	2025-01-08 00:03:21.695686	500	Friday	f	t	\N
136	Sami Ullah Khan	Student	2025-01-08	2025-01-08 00:05:00.159407	2025-01-08 00:05:00.174646	500	Wednesday	f	f	\N
137	Jeff Bezos	Student	2025-01-08	2025-01-08 00:05:00.188499	2025-01-08 00:05:00.191278	500	Wednesday	f	f	\N
138	Hamid Mir	Student	2025-01-08	2025-01-08 00:05:00.196434	2025-01-08 22:20:07.875146	0	Wednesday	f	t	2025-01-08 17:19:01.932309+00
104	Sami Ullah Khan	Student	2024-12-26	2024-12-28 19:21:19	2025-01-08 00:14:54.093119	500	Thursday	f	t	\N
144	Saad Akhtar	Teacher	2025-01-08	2025-01-08 00:05:00.319118	2025-01-08 00:31:21.763367	0	Wednesday	f	t	2025-01-07 19:20:26.188889+00
139	Abdullah Shahid	Teacher	2025-01-08	2025-01-08 00:05:00.226779	2025-01-08 22:20:07.850398	0	Wednesday	f	t	2025-01-08 17:18:44.65694+00
143	Elon Musk	Student	2025-01-08	2025-01-08 00:05:00.305385	2025-01-08 22:20:07.884091	0	Wednesday	f	t	2025-01-08 17:19:09.706327+00
145	Sami Ullah Khan	Student	2025-01-09	2025-01-09 00:05:00.341349	2025-01-09 00:05:00.344701	500	Thursday	f	f	\N
146	Jeff Bezos	Student	2025-01-09	2025-01-09 00:05:00.352944	2025-01-09 00:05:00.354952	500	Thursday	f	f	\N
148	Abdullah Shahid	Teacher	2025-01-09	2025-01-09 00:05:00.364448	2025-01-09 00:05:00.366297	500	Thursday	f	f	\N
149	Athar Mehboob	Student	2025-01-09	2025-01-09 00:05:00.369501	2025-01-09 00:05:00.371299	500	Thursday	f	f	\N
150	Muhammad Ali	Student	2025-01-09	2025-01-09 00:05:00.375284	2025-01-09 00:05:00.376992	500	Thursday	f	f	\N
151	Bill Gates	Student	2025-01-09	2025-01-09 00:05:00.38037	2025-01-09 00:05:00.382375	500	Thursday	f	f	\N
152	Elon Musk	Student	2025-01-09	2025-01-09 00:05:00.385788	2025-01-09 00:05:00.387542	500	Thursday	f	f	\N
153	Saad Akhtar	Teacher	2025-01-09	2025-01-09 00:05:00.390877	2025-01-09 00:05:00.392776	500	Thursday	f	f	\N
\.


--
-- Data for Name: app_finepayment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_finepayment (id, payer_name, payer_email, amount, cardholder_name, payment_intent_id, payment_date, attendance_id) FROM stdin;
1	saad	saadakhtar30@gmail.com	500	Ali	pi_3QbS2LQx0O9gQckS1mbMG0GE	2024-12-30	110
2	saad	saadakhtar30@gmail.com	500	Zamir	pi_3QbS5iQx0O9gQckS1kRz3dOR	2024-12-29	109
3	saad	saadakhtar30@gmail.com	500	Ali	pi_3QbW47Qx0O9gQckS0iksE3hB	2024-12-30	85
4	saad	saadakhtar30@gmail.com	500	Sami 	pi_3Qbf96Qx0O9gQckS0xhO2ysh	2024-12-30	87
5	saad	saadakhtar30@gmail.com	500	Faisal Khan	pi_3QbzA9Qx0O9gQckS0Go1i7Hm	2024-12-31	13
6	saad	saadakhtar30@gmail.com	500	Ali Arayz	pi_3Qc7ZGQx0O9gQckS01T5kKnM	2024-12-31	15
7	bill	billgates@gmail.com	500	Faisal Khan	pi_3QcNILQx0O9gQckS1YgbGIs6	2025-01-01	21
8	saad	saadakhtar30@gmail.com	500	Athar	pi_3QcXqKQx0O9gQckS1f3SdIrn	2025-01-02	33
9	saad	saadakhtar30@gmail.com	500	Abdul Wahab	pi_3QdrkRQx0O9gQckS0R017gcK	2025-01-05	7
10	saad	saadakhtar30@gmail.com	500	Saad	pi_3Qds3UQx0O9gQckS1eP8Uxf6	2025-01-05	81
11	saad	saadakhtar30@gmail.com	500	Saad	pi_3Qds3tQx0O9gQckS1FUFCdTk	2025-01-05	111
12	saad	saadakhtar30@gmail.com	500	Saad	pi_3Qds4HQx0O9gQckS0BVzmq0S	2025-01-05	8
13	saad	saadakhtar30@gmail.com	500	Saad	pi_3Qdup6Qx0O9gQckS1p32N5B5	2025-01-05	41
14	saad	saadakhtar30@gmail.com	500	Elon millionaire	pi_3QeAAPQx0O9gQckS1y8rzY5x	2025-01-06	113
15	saad	saadakhtar30@gmail.com	500	Gareeb adami	pi_3QeAFfQx0O9gQckS01AsgLGm	2025-01-06	29
16	bill	billgates@gmail.com	500	saad	pi_3QeKzdQx0O9gQckS1zQdqJwH	2025-01-06	2
17	bill	billgates@gmail.com	500	Saad	pi_3QeL6KQx0O9gQckS02FwYYsa	2025-01-06	36
18	athar	atharmehboob@gmail.com	500	saad	pi_3QeLkiQx0O9gQckS1P8Vhwdz	2025-01-07	110
19	saad	saadakhtar30@gmail.com	500	saad	pi_3QeLpYQx0O9gQckS1bKN2uHI	2025-01-07	125
20	saad	saadakhtar30@gmail.com	500	saad	pi_3QeM44Qx0O9gQckS1usWmfW3	2025-01-07	107
21	saad	saadakhtar30@gmail.com	500	saad	pi_3QeM7GQx0O9gQckS1rlCvzTI	2025-01-07	72
22	saad	saadakhtar30@gmail.com	500	Fahad	pi_3QeMCCQx0O9gQckS0Y5p9Z6o	2025-01-07	40
23	saad	saadakhtar30@gmail.com	500	ali	pi_3QeMHsQx0O9gQckS087cKr6P	2025-01-07	106
24	bill	billgates@gmail.com	500	Sami	pi_3QeMMgQx0O9gQckS1cUsMAJr	2025-01-07	97
25	athar	atharmehboob@gmail.com	500	asdfg	pi_3QeWZqQx0O9gQckS1ekg6ZLu	2025-01-07	73
26	saad	saadakhtar30@gmail.com	500	Gareeb adami	pi_3QeY1FQx0O9gQckS0bDlfac6	2025-01-07	98
28	admin	admin@gmail.com	500	Saad	pi_3Qei2tQx0O9gQckS06N8Gx61	2025-01-08	3
29	admin	admin@gmail.com	500	Bill Gates	pi_3QeiCdQx0O9gQckS1qBAvt23	2025-01-08	14
30	admin	admin@gmail.com	500	Sami	pi_3QeiEIQx0O9gQckS1sjUWh3W	2025-01-08	104
31	bill	billgates@gmail.com	500	Elon	pi_3QeiIuQx0O9gQckS1LEARQlQ	2025-01-08	28
32	admin	admin@gmail.com	500	Manual Payment	Cash	2025-01-08	108
33	admin	admin@gmail.com	500	Manual Payment	Cash	2025-01-08	70
34	admin	admin@gmail.com	500	Manual Payment	Cash	2025-01-08	75
35	admin	admin@gmail.com	500	Hamid	pi_3QeuG1Qx0O9gQckS0Q3FKpIp	2025-01-08	79
36	admin	admin@gmail.com	500	Gareeb adami	pi_3QewQKQx0O9gQckS1Ne5XM8s	2025-01-08	24
37	admin	admin@gmail.com	500	Manual Payment	Cash	2025-01-08	17
38	admin	admin@gmail.com	500	Manual Payment	Cash	2025-01-08	82
\.


--
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_group (id, name) FROM stdin;
\.


--
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_group_permissions (id, group_id, permission_id) FROM stdin;
\.


--
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_permission (id, content_type_id, codename, name) FROM stdin;
1	1	add_logentry	Can add log entry
2	1	change_logentry	Can change log entry
3	1	delete_logentry	Can delete log entry
4	1	view_logentry	Can view log entry
5	2	add_permission	Can add permission
6	2	change_permission	Can change permission
7	2	delete_permission	Can delete permission
8	2	view_permission	Can view permission
9	3	add_group	Can add group
10	3	change_group	Can change group
11	3	delete_group	Can delete group
12	3	view_group	Can view group
13	4	add_user	Can add user
14	4	change_user	Can change user
15	4	delete_user	Can delete user
16	4	view_user	Can view user
17	5	add_contenttype	Can add content type
18	5	change_contenttype	Can change content type
19	5	delete_contenttype	Can delete content type
20	5	view_contenttype	Can view content type
21	6	add_session	Can add session
22	6	change_session	Can change session
23	6	delete_session	Can delete session
24	6	view_session	Can view session
25	7	add_attendance	Can add attendance
26	7	change_attendance	Can change attendance
27	7	delete_attendance	Can delete attendance
28	7	view_attendance	Can view attendance
30	9	add_finepayment	Can add fine payment
31	9	change_finepayment	Can change fine payment
32	9	delete_finepayment	Can delete fine payment
33	9	view_finepayment	Can view fine payment
34	10	add_taskresult	Can add task result
35	10	change_taskresult	Can change task result
36	10	delete_taskresult	Can delete task result
37	10	view_taskresult	Can view task result
38	11	add_chordcounter	Can add chord counter
39	11	change_chordcounter	Can change chord counter
40	11	delete_chordcounter	Can delete chord counter
41	11	view_chordcounter	Can view chord counter
42	12	add_groupresult	Can add group result
43	12	change_groupresult	Can change group result
44	12	delete_groupresult	Can delete group result
45	12	view_groupresult	Can view group result
46	13	add_crontabschedule	Can add crontab
47	13	change_crontabschedule	Can change crontab
48	13	delete_crontabschedule	Can delete crontab
49	13	view_crontabschedule	Can view crontab
50	14	add_intervalschedule	Can add interval
51	14	change_intervalschedule	Can change interval
52	14	delete_intervalschedule	Can delete interval
53	14	view_intervalschedule	Can view interval
54	15	add_periodictask	Can add periodic task
55	15	change_periodictask	Can change periodic task
56	15	delete_periodictask	Can delete periodic task
57	15	view_periodictask	Can view periodic task
58	16	add_periodictasks	Can add periodic task track
59	16	change_periodictasks	Can change periodic task track
60	16	delete_periodictasks	Can delete periodic task track
61	16	view_periodictasks	Can view periodic task track
62	17	add_solarschedule	Can add solar event
63	17	change_solarschedule	Can change solar event
64	17	delete_solarschedule	Can delete solar event
65	17	view_solarschedule	Can view solar event
66	18	add_clockedschedule	Can add clocked
67	18	change_clockedschedule	Can change clocked
68	18	delete_clockedschedule	Can delete clocked
69	18	view_clockedschedule	Can view clocked
\.


--
-- Data for Name: auth_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user (id, password, last_login, is_superuser, username, last_name, email, is_staff, is_active, date_joined, first_name) FROM stdin;
2	pbkdf2_sha256$870000$KtTNTQrZB10drEPvM4tQ7E$VNYw6+IBrkivf6rQ2Ue+pDE2Acet5OLm7SmMmB66ZHw=	2025-01-08 00:18:55.833605	f	bill	Gates	billgates@gmail.com	f	t	2024-12-21 19:28:47	Bill
3	pbkdf2_sha256$870000$NCMWCYRWYPjrVPiIXbKZ6Y$GDjZVcwnEzGC9zwl+0Z+TY7uIJ3AUKt8oK1HtBpk2+o=	2025-01-08 00:20:09.262977	f	athar	Mehboob	atharmehboob@gmail.com	f	t	2025-01-06 23:47:18	Athar
1	pbkdf2_sha256$870000$dfJVJ9KOEtT0vrmJokKbDN$PBHJrcQ09mzIkwNE3+J/SxPayiQaMLPoBgHe50GKGXE=	2025-01-08 18:40:49.289679	f	saad	Akhtar	saadakhtar30@gmail.com	t	t	2024-12-21 09:42:22	Saad
4	pbkdf2_sha256$870000$JoHZ21NV2F6BMUYDXkxkYh$NbYgwEdOkeMc8WRPTk7RbQ2fmrbKOD6BhTEbTWj27z4=	2025-01-09 12:16:53.067284	t	admin		admin@gmail.com	t	t	2025-01-07 22:38:39.20578	
\.


--
-- Data for Name: auth_user_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user_groups (id, user_id, group_id) FROM stdin;
\.


--
-- Data for Name: auth_user_user_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user_user_permissions (id, user_id, permission_id) FROM stdin;
\.


--
-- Data for Name: django_admin_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_admin_log (id, object_id, object_repr, action_flag, change_message, content_type_id, user_id, action_time) FROM stdin;
1	2	bill	1	[{"added": {}}]	4	1	2024-12-21 19:28:48
2	2	bill	2	[]	4	1	2024-12-21 19:29:27
3	1	saad	2	[{"changed": {"fields": ["Email address"]}}]	4	1	2024-12-21 19:30:48
4	2	bill	2	[{"changed": {"fields": ["Email address"]}}]	4	1	2024-12-21 19:31:13
6	1	Test	1	Test action	1	1	2024-12-29 20:12:45.018945
7	4	every 2 hours	1	[{"added": {}}]	14	1	2024-12-30 01:13:26.959034
8	2	0 2 * * * (m/h/dM/MY/d) Asia/Karachi	1	[{"added": {}}]	13	1	2024-12-30 01:14:38.247856
9	1	add_attendance_sheet: 0 2 * * * (m/h/dM/MY/d) Asia/Karachi	1	[{"added": {}}]	15	1	2024-12-30 01:16:18.540452
10	2	mark_attendance_sheet: every 2 hours	1	[{"added": {}}]	15	1	2024-12-30 01:16:52.350694
11	5	every 30 seconds	1	[{"added": {}}]	14	1	2024-12-30 01:26:42.15173
12	1	add_attendance_sheet: every 30 seconds	2	[{"changed": {"fields": ["Interval Schedule", "Crontab Schedule"]}}]	15	1	2024-12-30 01:27:07.705682
13	6	every 6 hours	1	[{"added": {}}]	14	1	2024-12-30 03:59:12.73259
14	1	add_attendance_sheet: every 6 hours	2	[{"changed": {"fields": ["Interval Schedule"]}}]	15	1	2024-12-30 04:00:08.585479
15	1	add_attendance_sheet: every 30 seconds	2	[{"changed": {"fields": ["Interval Schedule"]}}]	15	1	2024-12-30 04:34:50.04752
16	1	add_attendance_sheet: every 6 hours	2	[{"changed": {"fields": ["Interval Schedule"]}}]	15	1	2024-12-30 23:58:20.80919
17	2	mark_attendance_sheet: every 30 seconds	2	[{"changed": {"fields": ["Interval Schedule"]}}]	15	1	2024-12-30 23:58:45.155668
18	7	every 50 seconds	1	[{"added": {}}]	14	1	2024-12-31 00:12:45.310926
19	4	every 3 hours	2	[{"changed": {"fields": ["Number of Periods"]}}]	14	1	2024-12-31 00:12:56.95495
20	2	mark_attendance_sheet: every 50 seconds	2	[{"changed": {"fields": ["Interval Schedule"]}}]	15	1	2024-12-31 00:14:08.791776
21	2	mark_attendance_sheet: every 3 hours	2	[{"changed": {"fields": ["Interval Schedule"]}}]	15	1	2024-12-31 00:55:36.926664
22	1	add_attendance_sheet: every 30 seconds	2	[{"changed": {"fields": ["Interval Schedule"]}}]	15	1	2024-12-31 00:55:48.955138
23	1	add_attendance_sheet: every 30 seconds	2	[]	15	1	2024-12-31 01:20:54.393594
24	1	every 30 seconds	1	[{"added": {}}]	14	1	2024-12-31 02:47:28.173327
25	2	every 50 seconds	1	[{"added": {}}]	14	1	2024-12-31 02:47:36.731955
26	3	every hour	1	[{"added": {}}]	14	1	2024-12-31 02:47:46.353565
27	4	every 6 hours	1	[{"added": {}}]	14	1	2024-12-31 02:47:56.561002
28	2	5 * * * * (m/h/dM/MY/d) Asia/Karachi	1	[{"added": {}}]	13	1	2024-12-31 02:48:12.035036
29	2	1 * * * * (m/h/dM/MY/d) Asia/Karachi	2	[{"changed": {"fields": ["Minute(s)"]}}]	13	1	2024-12-31 02:48:26.963452
30	2	1 0 * * * (m/h/dM/MY/d) Asia/Karachi	2	[{"changed": {"fields": ["Hour(s)"]}}]	13	1	2024-12-31 02:48:45.651449
31	2	5 0 * * * (m/h/dM/MY/d) Asia/Karachi	2	[{"changed": {"fields": ["Minute(s)"]}}]	13	1	2024-12-31 02:48:57.823122
32	2	add_attendance_sheet: 5 0 * * * (m/h/dM/MY/d) Asia/Karachi	1	[{"added": {}}]	15	1	2024-12-31 02:49:34.239491
33	3	mark_attendance_sheet: every 30 seconds	1	[{"added": {}}]	15	1	2024-12-31 02:50:00.879377
34	3	mark_attendance_sheet: every hour	2	[{"changed": {"fields": ["Interval Schedule"]}}]	15	1	2024-12-31 02:52:18.927561
35	1	every 30 seconds	1	[{"added": {}}]	14	1	2025-01-01 00:28:15.022412
36	2	every hour	1	[{"added": {}}]	14	1	2025-01-01 00:28:33.656073
37	1	5 0 * * * (m/h/dM/MY/d) Asia/Karachi	1	[{"added": {}}]	13	1	2025-01-01 00:28:53.687507
38	1	add_attendance_sheet: every 30 seconds	1	[{"added": {}}]	15	1	2025-01-01 00:29:32.331511
39	2	mark_attendance_sheet: every hour	1	[{"added": {}}]	15	1	2025-01-01 00:29:59.316734
40	1	add_attendance_sheet: 5 0 * * * (m/h/dM/MY/d) Asia/Karachi	2	[{"changed": {"fields": ["Interval Schedule", "Crontab Schedule"]}}]	15	1	2025-01-01 00:31:56.485419
41	2	mark_attendance_sheet: every 30 seconds	2	[{"changed": {"fields": ["Task (registered)", "Interval Schedule"]}}]	15	1	2025-01-01 00:32:31.515409
42	2	mark_attendance_sheet: every 30 seconds	2	[{"changed": {"fields": ["Task (registered)"]}}]	15	1	2025-01-01 00:57:16.441826
43	1	add_attendance_sheet: 5 0 * * * (m/h/dM/MY/d) Asia/Karachi	2	[{"changed": {"fields": ["Task (registered)"]}}]	15	1	2025-01-01 00:57:36.083336
44	2	mark_attendance_sheet: every 30 seconds	3		15	1	2025-01-01 01:11:12.11517
45	1	add_attendance_sheet: 5 0 * * * (m/h/dM/MY/d) Asia/Karachi	3		15	1	2025-01-01 01:11:12.11517
46	4	add_attendance_sheet: 5 0 * * * (m/h/dM/MY/d) Asia/Karachi	1	[{"added": {}}]	15	1	2025-01-01 01:11:45.301278
47	5	mark_attendance_sheet: every 30 seconds	1	[{"added": {}}]	15	1	2025-01-01 01:12:07.78271
48	4	add_attendance_sheet: every 30 seconds	2	[{"changed": {"fields": ["Interval Schedule", "Crontab Schedule"]}}]	15	1	2025-01-02 00:46:32.136045
49	4	add_attendance_sheet: 5 0 * * * (m/h/dM/MY/d) Asia/Karachi	2	[{"changed": {"fields": ["Interval Schedule", "Crontab Schedule"]}}]	15	1	2025-01-02 00:48:52.00688
50	3	every 5 minutes	1	[{"added": {}}]	14	1	2025-01-02 01:25:31.779625
51	5	mark_attendance_sheet: every 5 minutes	2	[{"changed": {"fields": ["Interval Schedule"]}}]	15	1	2025-01-02 01:25:50.562815
52	5	mark_attendance_sheet: every 30 seconds	2	[{"changed": {"fields": ["Interval Schedule"]}}]	15	1	2025-01-04 03:18:17.914266
53	5	mark_attendance_sheet: every 5 minutes	2	[{"changed": {"fields": ["Interval Schedule"]}}]	15	1	2025-01-04 03:19:18.094314
54	34	30 18 * * * (m/h/dM/MY/d) Asia/Karachi	1	[{"added": {}}]	13	1	2025-01-05 17:03:48.781768
55	34	0 20 * * * (m/h/dM/MY/d) Asia/Karachi	2	[{"changed": {"fields": ["Minute(s)", "Hour(s)"]}}]	13	1	2025-01-05 17:04:11.943892
56	5	mark_attendance_sheet: 0 20 * * * (m/h/dM/MY/d) Asia/Karachi	2	[{"changed": {"fields": ["Interval Schedule", "Crontab Schedule"]}}]	15	1	2025-01-05 17:04:40.559646
57	2	bill	2	[{"changed": {"fields": ["First name", "Last name"]}}]	4	1	2025-01-06 22:15:49.563077
58	3	athar	1	[{"added": {}}]	4	1	2025-01-06 23:47:19.497069
59	3	athar	2	[{"changed": {"fields": ["First name", "Last name"]}}]	4	1	2025-01-06 23:47:39.61905
60	2	bill	2	[{"changed": {"fields": ["Last name"]}}]	4	1	2025-01-06 23:48:01.994706
61	2	bill	2	[{"changed": {"fields": ["Last name"]}}]	4	1	2025-01-07 00:05:31.929248
62	1	saad	2	[{"changed": {"fields": ["Superuser status"]}}]	4	4	2025-01-07 22:39:18.743415
63	1	saad	2	[{"changed": {"fields": ["First name", "Last name"]}}]	4	4	2025-01-07 22:42:45.88927
64	1	saad	2	[{"changed": {"fields": ["password"]}}]	4	4	2025-01-07 22:55:48.085327
\.


--
-- Data for Name: django_celery_beat_clockedschedule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_celery_beat_clockedschedule (id, clocked_time) FROM stdin;
\.


--
-- Data for Name: django_celery_beat_crontabschedule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_celery_beat_crontabschedule (id, minute, hour, day_of_week, day_of_month, month_of_year, timezone) FROM stdin;
1	5	0	*	*	*	Asia/Karachi
34	0	20	*	*	*	Asia/Karachi
2	0	4	*	*	*	Asia/Karachi
\.


--
-- Data for Name: django_celery_beat_intervalschedule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_celery_beat_intervalschedule (id, every, period) FROM stdin;
1	30	seconds
2	1	hours
3	5	minutes
\.


--
-- Data for Name: django_celery_beat_periodictask; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_celery_beat_periodictask (id, name, task, args, kwargs, queue, exchange, routing_key, expires, enabled, last_run_at, total_run_count, date_changed, description, crontab_id, interval_id, solar_id, one_off, start_time, priority, headers, clocked_id, expire_seconds) FROM stdin;
5	mark_attendance_sheet	app.tasks.mark_attendance_sheet	[]	{}	\N	\N	\N	\N	t	2025-01-08 15:00:00.036085+00	934	2025-01-08 15:00:40.440681+00		34	\N	\N	f	\N	\N	{}	\N	\N
4	add_attendance_sheet	app.tasks.add_attendance_sheet	[]	{}	\N	\N	\N	\N	t	2025-01-08 19:05:00.00167+00	9	2025-01-08 19:06:10.164148+00		1	\N	\N	f	\N	\N	{}	\N	\N
3	celery.backend_cleanup	celery.backend_cleanup	[]	{}	\N	\N	\N	\N	t	2025-01-08 23:00:00.001069+00	8	2025-01-08 23:00:25.098232+00		2	\N	\N	f	\N	\N	{}	\N	43200
\.


--
-- Data for Name: django_celery_beat_periodictasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_celery_beat_periodictasks (ident, last_update) FROM stdin;
1	2025-01-08 17:23:58.708235+00
\.


--
-- Data for Name: django_celery_beat_solarschedule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_celery_beat_solarschedule (id, event, latitude, longitude) FROM stdin;
\.


--
-- Data for Name: django_celery_results_chordcounter; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_celery_results_chordcounter (id, group_id, sub_tasks, count) FROM stdin;
\.


--
-- Data for Name: django_celery_results_groupresult; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_celery_results_groupresult (id, group_id, date_created, date_done, content_type, content_encoding, result) FROM stdin;
\.


--
-- Data for Name: django_celery_results_taskresult; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_celery_results_taskresult (id, task_id, status, content_type, content_encoding, result, date_done, traceback, meta, task_args, task_kwargs, task_name, worker, date_created, periodic_task_name) FROM stdin;
1009	53cd8a49-e0c1-4bf1-bf70-1a93d0fe9c09	SUCCESS	application/json	utf-8	null	2025-01-08 19:05:00.401907+00	\N	{"children": []}	\N	\N	\N	\N	2025-01-08 19:05:00.401897+00	\N
1010	f7c5d8d3-f05e-446f-a4f4-efb298f03aba	SUCCESS	application/json	utf-8	null	2025-01-08 23:00:00.60999+00	\N	{"children": []}	\N	\N	\N	\N	2025-01-08 23:00:00.609968+00	\N
1007	3de24f95-1c48-4bb9-be68-392155852e97	SUCCESS	application/json	utf-8	null	2025-01-07 23:00:00.63726+00	\N	{"children": []}	\N	\N	\N	\N	2025-01-07 23:00:00.637243+00	\N
1008	9321c995-ac99-4971-bf0c-4a49561223c6	SUCCESS	application/json	utf-8	null	2025-01-08 15:00:01.569318+00	\N	{"children": []}	\N	\N	\N	\N	2025-01-08 15:00:01.569291+00	\N
\.


--
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_content_type (id, app_label, model) FROM stdin;
1	admin	logentry
2	auth	permission
3	auth	group
4	auth	user
5	contenttypes	contenttype
6	sessions	session
7	app	attendance
9	app	finepayment
10	django_celery_results	taskresult
11	django_celery_results	chordcounter
12	django_celery_results	groupresult
13	django_celery_beat	crontabschedule
14	django_celery_beat	intervalschedule
15	django_celery_beat	periodictask
16	django_celery_beat	periodictasks
17	django_celery_beat	solarschedule
18	django_celery_beat	clockedschedule
\.


--
-- Data for Name: django_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_migrations (id, app, name, applied) FROM stdin;
1	contenttypes	0001_initial	2024-12-21 09:39:22
2	auth	0001_initial	2024-12-21 09:39:22
3	admin	0001_initial	2024-12-21 09:39:22
4	admin	0002_logentry_remove_auto_add	2024-12-21 09:39:22
5	admin	0003_logentry_add_action_flag_choices	2024-12-21 09:39:22
6	contenttypes	0002_remove_content_type_name	2024-12-21 09:39:22
7	auth	0002_alter_permission_name_max_length	2024-12-21 09:39:22
8	auth	0003_alter_user_email_max_length	2024-12-21 09:39:22
9	auth	0004_alter_user_username_opts	2024-12-21 09:39:22
10	auth	0005_alter_user_last_login_null	2024-12-21 09:39:22
11	auth	0006_require_contenttypes_0002	2024-12-21 09:39:22
12	auth	0007_alter_validators_add_error_messages	2024-12-21 09:39:22
13	auth	0008_alter_user_username_max_length	2024-12-21 09:39:22
14	auth	0009_alter_user_last_name_max_length	2024-12-21 09:39:22
15	auth	0010_alter_group_name_max_length	2024-12-21 09:39:22
16	auth	0011_update_proxy_permissions	2024-12-21 09:39:22
17	auth	0012_alter_user_first_name_max_length	2024-12-21 09:39:22
18	sessions	0001_initial	2024-12-21 09:39:22
19	app	0001_initial	2024-12-21 13:17:14
20	app	0002_remove_attendance_fine_remove_attendance_is_paid	2024-12-21 13:27:39
21	app	0003_alter_attendance_timestamp	2024-12-21 14:18:31
22	app	0004_attendance_fine	2024-12-21 14:18:31
23	app	0005_attendance_day	2024-12-21 14:46:41
24	app	0006_attendance_is_paid	2024-12-21 18:40:54
133	app	0002_alter_attendance_id	2025-01-02 01:08:05.074855
25	app	0007_alter_attendance_is_paid	2024-12-21 18:42:03.432164
26	app	0008_remove_attendance_is_paid	2024-12-29 18:34:33.197615
27	app	0009_attendance_is_paid	2024-12-29 18:35:25.998268
134	app	0003_alter_attendance_id	2025-01-02 01:08:06.199078
29	app	0010_finepayment	2024-12-29 19:19:14.116336
51	django_celery_results	0001_initial	2024-12-30 00:45:17.71389
52	django_celery_results	0002_add_task_name_args_kwargs	2024-12-30 00:45:18.848995
53	django_celery_results	0003_auto_20181106_1101	2024-12-30 00:45:19.30323
54	django_celery_results	0004_auto_20190516_0412	2024-12-30 00:45:21.372008
55	django_celery_results	0005_taskresult_worker	2024-12-30 00:45:22.96988
56	django_celery_results	0006_taskresult_date_created	2024-12-30 00:45:24.579611
57	django_celery_results	0007_remove_taskresult_hidden	2024-12-30 00:45:25.249087
58	django_celery_results	0008_chordcounter	2024-12-30 00:45:26.663169
59	django_celery_results	0009_groupresult	2024-12-30 00:45:33.580079
60	django_celery_results	0010_remove_duplicate_indices	2024-12-30 00:45:34.734463
61	django_celery_results	0011_taskresult_periodic_task_name	2024-12-30 00:45:35.646804
62	app	0011_remove_attendance_is_deleted_and_more	2024-12-30 02:18:33.168101
63	app	0012_attendance_is_deleted_attendance_is_paid	2024-12-30 02:20:09.290256
64	app	0013_alter_attendance_id	2024-12-30 02:28:16.597337
65	app	0014_remove_attendance_timestamp_alter_attendance_id	2024-12-30 02:37:33.639013
66	app	0015_attendance_timestamp	2024-12-30 02:37:59.820033
67	app	0016_alter_attendance_id	2024-12-30 02:41:22.57531
112	django_celery_beat	0001_initial	2025-01-01 00:26:28.845192
113	django_celery_beat	0002_auto_20161118_0346	2025-01-01 00:26:30.576809
114	django_celery_beat	0003_auto_20161209_0049	2025-01-01 00:26:31.39648
115	django_celery_beat	0004_auto_20170221_0000	2025-01-01 00:26:31.883216
116	django_celery_beat	0005_add_solarschedule_events_choices	2025-01-01 00:26:32.644592
117	django_celery_beat	0006_auto_20180322_0932	2025-01-01 00:26:34.906604
118	django_celery_beat	0007_auto_20180521_0826	2025-01-01 00:26:36.384899
119	django_celery_beat	0008_auto_20180914_1922	2025-01-01 00:26:36.882044
120	django_celery_beat	0006_auto_20180210_1226	2025-01-01 00:26:37.661042
121	django_celery_beat	0006_periodictask_priority	2025-01-01 00:26:38.844641
122	django_celery_beat	0009_periodictask_headers	2025-01-01 00:26:40.09314
123	django_celery_beat	0010_auto_20190429_0326	2025-01-01 00:26:40.724892
124	django_celery_beat	0011_auto_20190508_0153	2025-01-01 00:26:42.582916
125	django_celery_beat	0012_periodictask_expire_seconds	2025-01-01 00:26:43.286758
126	django_celery_beat	0013_auto_20200609_0727	2025-01-01 00:26:43.764354
127	django_celery_beat	0014_remove_clockedschedule_enabled	2025-01-01 00:26:44.942864
128	django_celery_beat	0015_edit_solarschedule_events_choices	2025-01-01 00:26:45.404389
129	django_celery_beat	0016_alter_crontabschedule_timezone	2025-01-01 00:26:46.103602
130	django_celery_beat	0017_alter_crontabschedule_month_of_year	2025-01-01 00:26:46.797571
131	django_celery_beat	0018_improve_crontab_helptext	2025-01-01 00:26:47.487005
132	django_celery_beat	0019_alter_periodictasks_options	2025-01-01 00:26:48.209772
\.


--
-- Data for Name: django_session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_session (session_key, session_data, expire_date) FROM stdin;
2phvfe99s4d5oozn1eh1bfj47zne5t9h	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tOw0E:C2bNklqV2MLiRgTxE3r1KfWauKuQdKuH2gA9hCN4Aag	2025-01-04 09:42:30
3hu5eetiahmza6czw4oabi768azuuoka	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tP07A:DI-FzgqO7RiKwMRo1mad4qXbZZYkL4was1uh3AWaBV0	2025-01-04 14:05:56
z7989ovhcygg988kjd8quwqcwq55hwgi	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tPMjA:fUQ8IKXtW9mCERLsevswSVl4cYXTqtvYLZQiCyprAzU	2025-01-05 14:14:40
2w2a2962ukhflwczp23keret87rvywb3	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tRbxg:OJrVnKnfXDbgRZkVDJ7EZ4hAf1Ft2_6qy6KTNzTUFUU	2025-01-11 18:54:56
l786xf1u7shl9emkaia630x8kwpu31y2	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tRc9l:4o2L8ZpkD525vs0fffelQQnQvlnjDqZwylontUyzsuo	2025-01-11 19:07:25
h8ydf04dmtpvfsdapj4sgqxhdvazxy8z	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tRuU5:RwjKjPMGuoKYI-Hm_Ymd8rYw3f70G7uUH8bKgfS0aS8	2025-01-12 14:41:37
o7qkswyx33tixp2tg7wsei3hvwq2ip2z	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tRxO4:V3Z8dMEwGdFBDL_06vFCc4Q8J2SLFAdylzlTq7tN5iM	2025-01-12 17:47:36.537879
wy2necreopzuu74zvok471itthw7y9vd	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tRzqJ:fyQBt0b9JZc6kH3XK8cEev7UqR9-GqyiAa4fKlGsuTQ	2025-01-13 01:24:55.197509
iru3u1d10d6g4hbmn3zl96djsccw4v88	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tRzqJ:fyQBt0b9JZc6kH3XK8cEev7UqR9-GqyiAa4fKlGsuTQ	2025-01-13 01:24:55.326517
p2kjk0m12idom8fv8s488l4mcgy65k6e	.eJxVjDsOwjAQBe_iGlleQtYJJT1nsPZnHECJFCcV4u4QKQW0b2beyyVal5LWanMa1J3dyR1-NyZ52LgBvdN4m7xM4zIP7DfF77T666T2vOzu30GhWr41CjJYxh5EIktsAnOn0KL1QUygg2wYFaDhTG0mDtGwEz4GVW0puvcHCc85Gg:1tVmmj:irKOEQcKHw3cy7uYNyajMb-s0pqiHfqbUhKbCJn1jng	2025-01-23 12:16:53.284192
i0g4qryxv5ewg78gpmayo8nhv77v2ddj	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tSKxY:raQWujdHUF4GvNdx-Ys9hYJ5NxQrDXSyxWSxHJANGgQ	2025-01-13 23:57:48.530569
o5xua74q4j5cl7v1amm5qc8dltqs613m	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tUrFn:k_qkeOEWyuAGYZasJADqGLMDDLg-mjjNPQFYDx51GpI	2025-01-20 22:51:03.705563
avpw746wxxd6yxjzfj5jyr1upy115hma	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tSMFT:0_Zxrlq8alM1-Yj_iTSHS9gCO0CjJ1-BSW8nlN8w1s4	2025-01-14 01:20:23.717019
tjv9vytxyzagza4pf689vghcf1h4o9gv	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tShhn:hkoyKdDMjg-K9yA9uoL4KNhX-tK3NEGbZT2D6IcDJiE	2025-01-15 00:15:03.279241
dyzqmgctllo0ccd4xl3deivxpoqhaad6	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tSioS:PXgz4lKcaeUiib6fG12IvRIGW9aTzpvHpKZTrt4a2Is	2025-01-15 01:26:00.328644
0qoudz7poaplncq1fdt33d6a0qwt68r2	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tT4tQ:dgcWLBD2DYxrMvjsxjWlxxZX40qh2h8_CpYlbpLM2PM	2025-01-16 01:00:36.390113
1g1kx572bzbabputi66pu22qyor9bp5v	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tT5Gb:GavLVOvKKk5920GZNDx-coa3WCvMpdBetv9b77H4caM	2025-01-16 01:24:33.388867
j10oa7lyg6r1n0fwbnprasq8zi2fi57m	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tTpxr:wjOeQltVSR0U0jUsDBZKTclZnkit7LnXPLhoDstjQAs	2025-01-18 03:16:19.099923
2mksl5gg6oetc2feoxojpbocfv3qbu5g	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tTqEG:5QBhvomVO3xjC58x-6YgIMsYi4c3EAM6iKTf8rWG4_w	2025-01-18 03:33:16.16578
elb9x3dzxmgmmt92bui8h6ike9imc547	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tUBUk:WmxqsCT2mhHyEnuD6CbIAEHomZXE24i3bfNMkErzBFw	2025-01-19 02:15:42.064707
2hcogl6u6dxx64n7zo1kqs18q4hzcpxo	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tUBrM:bdpRyB9bQVk-fkz2GObUdnJk-iyqs9pQWwFEo-jNH-E	2025-01-19 02:39:04.545912
0lzk6uo061g6bwuszj97jx6fteryrdcr	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tUNQ2:HgQJ_HIilYVZQ8DZmOVJ_HvmrNXFbRMVui2sahJbNFw	2025-01-19 14:59:38.566042
unbql8qffq94qb8j4gkhltms08y6adpz	.eJxVjMsOwiAQRf-FtSFAebp07zcQmBmkaiAp7cr479qkC93ec859sZi2tcZt0BJnZGem2Ol3ywke1HaA99RunUNv6zJnviv8oINfO9Lzcrh_BzWN-q3BILlSQoGgJquBMKH3JJR1IpkwFRTWBqLsJycdFZSotTVaIkjhQmHvDwcUOFI:1tUP7S:15lNbS8WImgm1QbPPTImr9p411Wm4ItbG-mndzEEfcQ	2025-01-19 16:48:34.115684
inhnx4gleyxuirfb1654mc199h9tpe6q	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tUVxE:lEFKSPQarWCPhQPdoZ-RDBZdugXZLY2U-rzw8aPPIJQ	2025-01-20 00:06:28.465582
pl9p4pcuo2t2x1ec7sknkhopgcmt18sq	.eJxVjEEOwiAQAP_C2RCWBUo9evcNZBdQqgaS0p6MfzckPeh1ZjJvEWjfSth7XsOSxFmAOP0ypvjMdYj0oHpvMra6rQvLkcjDdnltKb8uR_s3KNTL2GoCADKRvNaklCKFk5ssI0Xlo_WMwCYDzmhp9tE5BcjGp5vPGbURny-6Vzbm:1tUXDO:O34gjIrxudA4wNb4Qt49eCrVWGJwLNxHcmrjavMUjuU	2025-01-20 01:27:14.56217
irmc52okotuue97r3uu76d4xb40rfc0o	.eJxVjDsOwjAQBe_iGlleQtYJJT1nsPZnHECJFCcV4u4QKQW0b2beyyVal5LWanMa1J3dyR1-NyZ52LgBvdN4m7xM4zIP7DfF77T666T2vOzu30GhWr41CjJYxh5EIktsAnOn0KL1QUygg2wYFaDhTG0mDtGwEz4GVW0puvcHCc85Gg:1tVREz:6s9GaYIjtZj1FBPMPwkIwy7ohv7s_R1FFJx9ZvMMmJ4	2025-01-22 13:16:37.103459
09kspiqskwastnsnzwggo27a3sokrjpu	.eJxVjDsOwjAQBe_iGlleQtYJJT1nsPZnHECJFCcV4u4QKQW0b2beyyVal5LWanMa1J3dyR1-NyZ52LgBvdN4m7xM4zIP7DfF77T666T2vOzu30GhWr41CjJYxh5EIktsAnOn0KL1QUygg2wYFaDhTG0mDtGwEz4GVW0puvcHCc85Gg:1tVRFo:YA3BZEax9540d1SqFsHFddZt-lIPvEXaBAuDjp1b4jQ	2025-01-22 13:17:28.627117
acjfwxhgg6sl1b7p6lrqqrhtgyit7e35	.eJxVjDsOwjAQBe_iGlleQtYJJT1nsPZnHECJFCcV4u4QKQW0b2beyyVal5LWanMa1J3dyR1-NyZ52LgBvdN4m7xM4zIP7DfF77T666T2vOzu30GhWr41CjJYxh5EIktsAnOn0KL1QUygg2wYFaDhTG0mDtGwEz4GVW0puvcHCc85Gg:1tVWLu:cy4TCKeVIhv4OoglmeAgUshhsrGmQn0bTR5L7ZQ7ArE	2025-01-22 18:44:06.648152
rizs5k71c8dzl4siwksvmwks2poenqat	.eJxVjDsOwjAQBe_iGlleQtYJJT1nsPZnHECJFCcV4u4QKQW0b2beyyVal5LWanMa1J3dyR1-NyZ52LgBvdN4m7xM4zIP7DfF77T666T2vOzu30GhWr41CjJYxh5EIktsAnOn0KL1QUygg2wYFaDhTG0mDtGwEz4GVW0puvcHCc85Gg:1tVTB6:eP5Psu6B53Wq0ZfVf7BskKGXkAlCt0-z5DT5L2vMIvM	2025-01-22 15:20:44.251693
jcpomu1zqbdj5j7jtvwo20tquw8fej2k	.eJxVjDsOwjAQBe_iGlleQtYJJT1nsPZnHECJFCcV4u4QKQW0b2beyyVal5LWanMa1J3dyR1-NyZ52LgBvdN4m7xM4zIP7DfF77T666T2vOzu30GhWr41CjJYxh5EIktsAnOn0KL1QUygg2wYFaDhTG0mDtGwEz4GVW0puvcHCc85Gg:1tVZiV:fuMW8nuD5AAkiuivSbV3fO2iM4V6MAl2Xpen7NtvFCM	2025-01-22 22:19:39.687377
w8nw4xhjsnehd18p7n2xo0w8fgmsryt4	.eJxVjMsOwiAQRf-FtSFAebp07zcQmBmkaiAp7cr479qkC93ec859sZi2tcZt0BJnZGem2Ol3ywke1HaA99RunUNv6zJnviv8oINfO9Lzcrh_BzWN-q3BILlSQoGgJquBMKH3JJR1IpkwFRTWBqLsJycdFZSotTVaIkjhQmHvDwcUOFI:1tV3Ls:SiIu3uWbq7mSYlz6PcDcVWbmxf31pNq-k3BuTVr_0TM	2025-01-21 11:46:08.691799
46udv6juxrd8sdwhjcc4uwy5z21bsq5h	.eJxVjssOgjAURP-la9K0Yh-ydO83kPuqoNgmUFbGfxcSFro9M3Myb9XDWod-XWTuR1adOqvmlyHQU_Ie8APyvWgquc4j6r2ij3TRt8IyXY_un2CAZdjWnjxaSf5iiQJSaA1iZOu8XAwJ2WiT-MDWtpjAJUATxEfCk2FmB2GTpjFLD6-y5qo6Z8xB9texbRRDFdXldZo-X8h8RtQ:1tVE5H:3SobBdg0aXWYHOwFIS-CEc87u2paXS6aNWF-CUn0t9Y	2025-01-21 23:13:43.194643
gtt6ohum102eylglj4anvzj383q0l9x5	.eJxVjDsOwjAQBe_iGlleQtYJJT1nsPZnHECJFCcV4u4QKQW0b2beyyVal5LWanMa1J3dyR1-NyZ52LgBvdN4m7xM4zIP7DfF77T666T2vOzu30GhWr41CjJYxh5EIktsAnOn0KL1QUygg2wYFaDhTG0mDtGwEz4GVW0puvcHCc85Gg:1tVEzq:5tqI0oj0PeMJdAybR-pDjywEy7TM40J8P0SZQQHOlHE	2025-01-22 00:12:10.590968
ibc9tyhco19nxg3uvc67hy6ak9mn8z2q	.eJxVjDsOwyAQBe9CHSHMz5Ayvc-AFnYJTiKQjF1FuXtsyUXSvpl5bxZgW0vYOi1hRnZlil1-twjpSfUA-IB6bzy1ui5z5IfCT9r51JBet9P9OyjQy17LAaxKUqDPCUUc0ZEn600C9DgYR0A6u5GEJmld9jmKrFWytHfCqMw-XwJHOKQ:1tVF7Z:v_eTvNCX-5owKFmV5ZJeMdGYN_sMT-rooPGtdRvxUmE	2025-01-22 00:20:09.265252
02rbssdj3yqrx8s5kwgutec7ebsg5o9q	.eJxVjDsOwjAQBe_iGlleQtYJJT1nsPZnHECJFCcV4u4QKQW0b2beyyVal5LWanMa1J3dyR1-NyZ52LgBvdN4m7xM4zIP7DfF77T666T2vOzu30GhWr41CjJYxh5EIktsAnOn0KL1QUygg2wYFaDhTG0mDtGwEz4GVW0puvcHCc85Gg:1tVFHp:2jxnfi98jE5NQpwLaggEN49TcjySFBzh2T1FMf1Nc9g	2025-01-22 00:30:45.99687
\.


--
-- Name: app_attendance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.app_attendance_id_seq', 153, true);


--
-- Name: app_finepayment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.app_finepayment_id_seq', 38, true);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_permission_id_seq', 95, true);


--
-- Name: auth_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_user_id_seq', 35, true);


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_admin_log_id_seq', 64, true);


--
-- Name: django_celery_beat_clockedschedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_celery_beat_clockedschedule_id_seq', 1, false);


--
-- Name: django_celery_beat_crontabschedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_celery_beat_crontabschedule_id_seq', 66, true);


--
-- Name: django_celery_beat_intervalschedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_celery_beat_intervalschedule_id_seq', 33, true);


--
-- Name: django_celery_beat_periodictask_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_celery_beat_periodictask_id_seq', 33, true);


--
-- Name: django_celery_beat_solarschedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_celery_beat_solarschedule_id_seq', 1, false);


--
-- Name: django_celery_results_chordcounter_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_celery_results_chordcounter_id_seq', 1, false);


--
-- Name: django_celery_results_groupresult_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_celery_results_groupresult_id_seq', 1, false);


--
-- Name: django_celery_results_taskresult_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_celery_results_taskresult_id_seq', 1010, true);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_content_type_id_seq', 41, true);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_migrations_id_seq', 156, true);


--
-- Name: app_finepayment app_finepayment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_finepayment
    ADD CONSTRAINT app_finepayment_pkey PRIMARY KEY (id);


--
-- Name: django_celery_beat_clockedschedule django_celery_beat_clockedschedule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_clockedschedule
    ADD CONSTRAINT django_celery_beat_clockedschedule_pkey PRIMARY KEY (id);


--
-- Name: django_celery_beat_crontabschedule django_celery_beat_crontabschedule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_crontabschedule
    ADD CONSTRAINT django_celery_beat_crontabschedule_pkey PRIMARY KEY (id);


--
-- Name: django_celery_beat_intervalschedule django_celery_beat_intervalschedule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_intervalschedule
    ADD CONSTRAINT django_celery_beat_intervalschedule_pkey PRIMARY KEY (id);


--
-- Name: django_celery_beat_periodictask django_celery_beat_periodictask_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_periodictask
    ADD CONSTRAINT django_celery_beat_periodictask_name_key UNIQUE (name);


--
-- Name: django_celery_beat_periodictask django_celery_beat_periodictask_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_periodictask
    ADD CONSTRAINT django_celery_beat_periodictask_pkey PRIMARY KEY (id);


--
-- Name: django_celery_beat_periodictasks django_celery_beat_periodictasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_periodictasks
    ADD CONSTRAINT django_celery_beat_periodictasks_pkey PRIMARY KEY (ident);


--
-- Name: django_celery_beat_solarschedule django_celery_beat_solar_event_latitude_longitude_ba64999a_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_solarschedule
    ADD CONSTRAINT django_celery_beat_solar_event_latitude_longitude_ba64999a_uniq UNIQUE (event, latitude, longitude);


--
-- Name: django_celery_beat_solarschedule django_celery_beat_solarschedule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_solarschedule
    ADD CONSTRAINT django_celery_beat_solarschedule_pkey PRIMARY KEY (id);


--
-- Name: django_celery_results_chordcounter django_celery_results_chordcounter_group_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_results_chordcounter
    ADD CONSTRAINT django_celery_results_chordcounter_group_id_key UNIQUE (group_id);


--
-- Name: django_celery_results_chordcounter django_celery_results_chordcounter_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_results_chordcounter
    ADD CONSTRAINT django_celery_results_chordcounter_pkey PRIMARY KEY (id);


--
-- Name: django_celery_results_groupresult django_celery_results_groupresult_group_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_results_groupresult
    ADD CONSTRAINT django_celery_results_groupresult_group_id_key UNIQUE (group_id);


--
-- Name: django_celery_results_groupresult django_celery_results_groupresult_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_results_groupresult
    ADD CONSTRAINT django_celery_results_groupresult_pkey PRIMARY KEY (id);


--
-- Name: django_celery_results_taskresult django_celery_results_taskresult_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_results_taskresult
    ADD CONSTRAINT django_celery_results_taskresult_pkey PRIMARY KEY (id);


--
-- Name: django_celery_results_taskresult django_celery_results_taskresult_task_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_results_taskresult
    ADD CONSTRAINT django_celery_results_taskresult_task_id_key UNIQUE (task_id);


--
-- Name: app_attendance pk_app_attendance; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_attendance
    ADD CONSTRAINT pk_app_attendance PRIMARY KEY (id);


--
-- Name: auth_group pk_auth_group; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT pk_auth_group PRIMARY KEY (id);


--
-- Name: auth_group_permissions pk_auth_group_permissions; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT pk_auth_group_permissions PRIMARY KEY (id);


--
-- Name: auth_permission pk_auth_permission; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT pk_auth_permission PRIMARY KEY (id);


--
-- Name: auth_user pk_auth_user; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT pk_auth_user PRIMARY KEY (id);


--
-- Name: auth_user_groups pk_auth_user_groups; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT pk_auth_user_groups PRIMARY KEY (id);


--
-- Name: auth_user_user_permissions pk_auth_user_user_permissions; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT pk_auth_user_user_permissions PRIMARY KEY (id);


--
-- Name: django_admin_log pk_django_admin_log; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT pk_django_admin_log PRIMARY KEY (id);


--
-- Name: django_content_type pk_django_content_type; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT pk_django_content_type PRIMARY KEY (id);


--
-- Name: django_migrations pk_django_migrations; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT pk_django_migrations PRIMARY KEY (id);


--
-- Name: django_session pk_django_session; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT pk_django_session PRIMARY KEY (session_key);


--
-- Name: app_finepayment_attendance_id_8c73bf44; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_finepayment_attendance_id_8c73bf44 ON public.app_finepayment USING btree (attendance_id);


--
-- Name: auth_group_permissions_group_id_b120cbf9_auth_group_permissions; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9_auth_group_permissions ON public.auth_group_permissions USING btree (group_id);


--
-- Name: auth_group_permissions_group_id_permission_id_0cd325b0_uniq_aut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX auth_group_permissions_group_id_permission_id_0cd325b0_uniq_aut ON public.auth_group_permissions USING btree (group_id, permission_id);


--
-- Name: auth_group_permissions_permission_id_84c5c92e_auth_group_permis; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e_auth_group_permis ON public.auth_group_permissions USING btree (permission_id);


--
-- Name: auth_permission_content_type_id_2f476e4b_auth_permission; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_permission_content_type_id_2f476e4b_auth_permission ON public.auth_permission USING btree (content_type_id);


--
-- Name: auth_permission_content_type_id_codename_01ab375a_uniq_auth_per; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX auth_permission_content_type_id_codename_01ab375a_uniq_auth_per ON public.auth_permission USING btree (content_type_id, codename);


--
-- Name: auth_user_groups_group_id_97559544_auth_user_groups; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_groups_group_id_97559544_auth_user_groups ON public.auth_user_groups USING btree (group_id);


--
-- Name: auth_user_groups_user_id_6a12ed8b_auth_user_groups; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_groups_user_id_6a12ed8b_auth_user_groups ON public.auth_user_groups USING btree (user_id);


--
-- Name: auth_user_groups_user_id_group_id_94350c0c_uniq_auth_user_group; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX auth_user_groups_user_id_group_id_94350c0c_uniq_auth_user_group ON public.auth_user_groups USING btree (user_id, group_id);


--
-- Name: auth_user_user_permissions_permission_id_1fbb5f2c_auth_user_use; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_user_permissions_permission_id_1fbb5f2c_auth_user_use ON public.auth_user_user_permissions USING btree (permission_id);


--
-- Name: auth_user_user_permissions_user_id_a95ead1b_auth_user_user_perm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_user_permissions_user_id_a95ead1b_auth_user_user_perm ON public.auth_user_user_permissions USING btree (user_id);


--
-- Name: auth_user_user_permissions_user_id_permission_id_14a6b632_uniq_; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX auth_user_user_permissions_user_id_permission_id_14a6b632_uniq_ ON public.auth_user_user_permissions USING btree (user_id, permission_id);


--
-- Name: django_admin_log_content_type_id_c4bce8eb_django_admin_log; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb_django_admin_log ON public.django_admin_log USING btree (content_type_id);


--
-- Name: django_admin_log_user_id_c564eba6_django_admin_log; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_admin_log_user_id_c564eba6_django_admin_log ON public.django_admin_log USING btree (user_id);


--
-- Name: django_cele_date_cr_bd6c1d_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_cele_date_cr_bd6c1d_idx ON public.django_celery_results_groupresult USING btree (date_created);


--
-- Name: django_cele_date_cr_f04a50_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_cele_date_cr_f04a50_idx ON public.django_celery_results_taskresult USING btree (date_created);


--
-- Name: django_cele_date_do_caae0e_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_cele_date_do_caae0e_idx ON public.django_celery_results_groupresult USING btree (date_done);


--
-- Name: django_cele_date_do_f59aad_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_cele_date_do_f59aad_idx ON public.django_celery_results_taskresult USING btree (date_done);


--
-- Name: django_cele_status_9b6201_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_cele_status_9b6201_idx ON public.django_celery_results_taskresult USING btree (status);


--
-- Name: django_cele_task_na_08aec9_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_cele_task_na_08aec9_idx ON public.django_celery_results_taskresult USING btree (task_name);


--
-- Name: django_cele_worker_d54dd8_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_cele_worker_d54dd8_idx ON public.django_celery_results_taskresult USING btree (worker);


--
-- Name: django_celery_beat_periodictask_clocked_id_47a69f82; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_celery_beat_periodictask_clocked_id_47a69f82 ON public.django_celery_beat_periodictask USING btree (clocked_id);


--
-- Name: django_celery_beat_periodictask_crontab_id_d3cba168; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_celery_beat_periodictask_crontab_id_d3cba168 ON public.django_celery_beat_periodictask USING btree (crontab_id);


--
-- Name: django_celery_beat_periodictask_interval_id_a8ca27da; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_celery_beat_periodictask_interval_id_a8ca27da ON public.django_celery_beat_periodictask USING btree (interval_id);


--
-- Name: django_celery_beat_periodictask_name_265a36b7_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_celery_beat_periodictask_name_265a36b7_like ON public.django_celery_beat_periodictask USING btree (name varchar_pattern_ops);


--
-- Name: django_celery_beat_periodictask_solar_id_a87ce72c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_celery_beat_periodictask_solar_id_a87ce72c ON public.django_celery_beat_periodictask USING btree (solar_id);


--
-- Name: django_celery_results_chordcounter_group_id_1f70858c_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_celery_results_chordcounter_group_id_1f70858c_like ON public.django_celery_results_chordcounter USING btree (group_id varchar_pattern_ops);


--
-- Name: django_celery_results_groupresult_group_id_a085f1a9_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_celery_results_groupresult_group_id_a085f1a9_like ON public.django_celery_results_groupresult USING btree (group_id varchar_pattern_ops);


--
-- Name: django_celery_results_taskresult_task_id_de0d95bf_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_celery_results_taskresult_task_id_de0d95bf_like ON public.django_celery_results_taskresult USING btree (task_id varchar_pattern_ops);


--
-- Name: django_content_type_app_label_model_76bd3d3b_uniq_django_conten; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX django_content_type_app_label_model_76bd3d3b_uniq_django_conten ON public.django_content_type USING btree (app_label, model);


--
-- Name: django_session_expire_date_a5c62663_django_session; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_session_expire_date_a5c62663_django_session ON public.django_session USING btree (expire_date);


--
-- Name: sqlite_autoindex_auth_group_1_auth_group; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX sqlite_autoindex_auth_group_1_auth_group ON public.auth_group USING btree (name);


--
-- Name: sqlite_autoindex_auth_user_1_auth_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX sqlite_autoindex_auth_user_1_auth_user ON public.auth_user USING btree (username);


--
-- Name: app_finepayment app_finepayment_attendance_id_8c73bf44_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_finepayment
    ADD CONSTRAINT app_finepayment_attendance_id_8c73bf44_fk FOREIGN KEY (attendance_id) REFERENCES public.app_attendance(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_celery_beat_periodictask django_celery_beat_p_clocked_id_47a69f82_fk_django_ce; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_periodictask
    ADD CONSTRAINT django_celery_beat_p_clocked_id_47a69f82_fk_django_ce FOREIGN KEY (clocked_id) REFERENCES public.django_celery_beat_clockedschedule(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_celery_beat_periodictask django_celery_beat_p_crontab_id_d3cba168_fk_django_ce; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_periodictask
    ADD CONSTRAINT django_celery_beat_p_crontab_id_d3cba168_fk_django_ce FOREIGN KEY (crontab_id) REFERENCES public.django_celery_beat_crontabschedule(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_celery_beat_periodictask django_celery_beat_p_interval_id_a8ca27da_fk_django_ce; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_periodictask
    ADD CONSTRAINT django_celery_beat_p_interval_id_a8ca27da_fk_django_ce FOREIGN KEY (interval_id) REFERENCES public.django_celery_beat_intervalschedule(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_celery_beat_periodictask django_celery_beat_p_solar_id_a87ce72c_fk_django_ce; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_celery_beat_periodictask
    ADD CONSTRAINT django_celery_beat_p_solar_id_a87ce72c_fk_django_ce FOREIGN KEY (solar_id) REFERENCES public.django_celery_beat_solarschedule(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT CREATE ON SCHEMA public TO PUBLIC;


--
-- Name: extension_before_drop; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER extension_before_drop ON ddl_command_start
   EXECUTE FUNCTION _heroku.extension_before_drop();


ALTER EVENT TRIGGER extension_before_drop OWNER TO postgres;

--
-- Name: log_create_ext; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER log_create_ext ON ddl_command_end
   EXECUTE FUNCTION _heroku.create_ext();


ALTER EVENT TRIGGER log_create_ext OWNER TO postgres;

--
-- Name: log_drop_ext; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER log_drop_ext ON sql_drop
   EXECUTE FUNCTION _heroku.drop_ext();


ALTER EVENT TRIGGER log_drop_ext OWNER TO postgres;

--
-- Name: validate_extension; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER validate_extension ON ddl_command_end
   EXECUTE FUNCTION _heroku.validate_extension();


ALTER EVENT TRIGGER validate_extension OWNER TO postgres;

--
-- PostgreSQL database dump complete
--

