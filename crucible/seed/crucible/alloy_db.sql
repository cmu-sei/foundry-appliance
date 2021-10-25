--
-- PostgreSQL database dump
--

-- Dumped from database version 11.9
-- Dumped by pg_dump version 13.4

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

DROP DATABASE alloy_db;
--
-- Name: alloy_db; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE alloy_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.UTF-8';


ALTER DATABASE alloy_db OWNER TO postgres;

\connect alloy_db

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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

--
-- Name: __EFMigrationsHistory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL
);


ALTER TABLE public."__EFMigrationsHistory" OWNER TO postgres;

--
-- Name: event_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_templates (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    date_created timestamp without time zone NOT NULL,
    date_modified timestamp without time zone,
    created_by uuid NOT NULL,
    modified_by uuid,
    view_id uuid,
    directory_id uuid,
    scenario_template_id uuid,
    name text,
    description text,
    duration_hours integer NOT NULL,
    is_published boolean DEFAULT false NOT NULL,
    use_dynamic_host boolean DEFAULT false NOT NULL
);


ALTER TABLE public.event_templates OWNER TO postgres;

--
-- Name: event_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    date_created timestamp without time zone NOT NULL,
    date_modified timestamp without time zone,
    created_by uuid NOT NULL,
    modified_by uuid,
    user_id uuid NOT NULL,
    event_id uuid NOT NULL
);


ALTER TABLE public.event_users OWNER TO postgres;

--
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    date_created timestamp without time zone NOT NULL,
    date_modified timestamp without time zone,
    created_by uuid NOT NULL,
    modified_by uuid,
    user_id uuid NOT NULL,
    username text,
    event_template_id uuid,
    view_id uuid,
    workspace_id uuid,
    run_id uuid,
    scenario_id uuid,
    name text,
    description text,
    status integer NOT NULL,
    launch_date timestamp without time zone,
    end_date timestamp without time zone,
    expiration_date timestamp without time zone,
    internal_status integer DEFAULT 0 NOT NULL,
    status_date timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
    failure_count integer DEFAULT 0 NOT NULL,
    last_end_internal_status integer DEFAULT 0 NOT NULL,
    last_end_status integer DEFAULT 0 NOT NULL,
    last_launch_internal_status integer DEFAULT 0 NOT NULL,
    last_launch_status integer DEFAULT 0 NOT NULL,
    share_code text
);


ALTER TABLE public.events OWNER TO postgres;

--
-- Data for Name: __EFMigrationsHistory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."__EFMigrationsHistory" ("MigrationId", "ProductVersion") FROM stdin;
20190719183445_Initial_Migration	3.1.0
20190813175524_internalStatus	3.1.0
20200317180127_definitionFlags	3.1.0
20200409191451_FailureCount	3.1.0
20200507204242_nounChange	3.1.0
20200511160116_NewNouns	3.1.0
20200514151407_renameIndexes	3.1.0
20210419180942_Share_Code_Migration	3.1.0
20210429142237_Event_User_Migration	3.1.0
\.


--
-- Data for Name: event_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.event_templates (id, date_created, date_modified, created_by, modified_by, view_id, directory_id, scenario_template_id, name, description, duration_hours, is_published, use_dynamic_host) FROM stdin;
146db1ed-b018-4b34-b10e-663253746342	2021-12-01 18:11:56.887181	2021-12-01 18:12:23.621909	dee684c5-2eaf-401a-915b-d3d4320fe5d5	dee684c5-2eaf-401a-915b-d3d4320fe5d5	5ecdbed4-8513-4729-b17b-21c930be9ae9	4f45e422-088e-42a0-bbfa-3b9dfc1cc98e	\N	Example Event	Example Event	4	t	f
\.


--
-- Data for Name: event_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.event_users (id, date_created, date_modified, created_by, modified_by, user_id, event_id) FROM stdin;
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.events (id, date_created, date_modified, created_by, modified_by, user_id, username, event_template_id, view_id, workspace_id, run_id, scenario_id, name, description, status, launch_date, end_date, expiration_date, internal_status, status_date, failure_count, last_end_internal_status, last_end_status, last_launch_internal_status, last_launch_status, share_code) FROM stdin;
94f50827-e0c9-4295-9278-70129a5d60c1	2021-12-01 18:49:29.888562	2021-12-01 18:51:00.345484	dee684c5-2eaf-401a-915b-d3d4320fe5d5	\N	dee684c5-2eaf-401a-915b-d3d4320fe5d5	Administrator	146db1ed-b018-4b34-b10e-663253746342	\N	\N	\N	\N	\N	\N	4	\N	\N	\N	34	2021-12-01 18:51:00.345302	1	0	0	2	1	\N
d1b2d79f-9c38-4bb2-b0b3-e322238c793b	2021-12-01 19:35:16.069383	2021-12-01 19:46:16.725597	dee684c5-2eaf-401a-915b-d3d4320fe5d5	\N	dee684c5-2eaf-401a-915b-d3d4320fe5d5	Administrator	146db1ed-b018-4b34-b10e-663253746342	ddb5e19a-e5f7-4377-a702-4d926b6e47c9	ed449b98-bea6-48be-9375-8180b57e69e9	c027d522-e3e7-4938-a12e-944d925a0a36	\N	Example Event	Example Event	10	2021-12-01 19:37:21.043446	2021-12-01 19:44:46.418248	2021-12-01 23:37:21.043446	21	2021-12-01 19:46:16.725115	1	21	11	0	0	\N
\.


--
-- Name: __EFMigrationsHistory PK___EFMigrationsHistory; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."__EFMigrationsHistory"
    ADD CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId");


--
-- Name: event_templates PK_event_templates; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_templates
    ADD CONSTRAINT "PK_event_templates" PRIMARY KEY (id);


--
-- Name: event_users PK_event_users; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_users
    ADD CONSTRAINT "PK_event_users" PRIMARY KEY (id);


--
-- Name: events PK_events; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT "PK_events" PRIMARY KEY (id);


--
-- Name: IX_event_users_event_id_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IX_event_users_event_id_user_id" ON public.event_users USING btree (event_id, user_id);


--
-- Name: IX_events_event_template_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_events_event_template_id" ON public.events USING btree (event_template_id);


--
-- Name: event_users FK_event_users_events_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_users
    ADD CONSTRAINT "FK_event_users_events_event_id" FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: events FK_events_event_templates_event_template_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT "FK_events_event_templates_event_template_id" FOREIGN KEY (event_template_id) REFERENCES public.event_templates(id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

