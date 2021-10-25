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
-- Name: applies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.applies (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    run_id uuid NOT NULL,
    status integer NOT NULL,
    output text
);


ALTER TABLE public.applies OWNER TO postgres;

--
-- Name: directories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text,
    project_id uuid NOT NULL,
    parent_id uuid,
    path text,
    terraform_version text
);


ALTER TABLE public.directories OWNER TO postgres;

--
-- Name: file_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_versions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    file_id uuid NOT NULL,
    name text,
    modified_by_id uuid,
    content text,
    date_saved timestamp without time zone,
    tag text,
    date_tagged timestamp without time zone,
    tagged_by_id uuid
);


ALTER TABLE public.file_versions OWNER TO postgres;

--
-- Name: files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.files (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text,
    directory_id uuid NOT NULL,
    content text,
    workspace_id uuid,
    date_saved timestamp without time zone,
    is_deleted boolean DEFAULT false NOT NULL,
    modified_by_id uuid,
    locked_by_id uuid,
    administratively_locked boolean DEFAULT false NOT NULL
);


ALTER TABLE public.files OWNER TO postgres;

--
-- Name: host_machines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.host_machines (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text,
    workspace_id uuid NOT NULL,
    host_id uuid NOT NULL
);


ALTER TABLE public.host_machines OWNER TO postgres;

--
-- Name: hosts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hosts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text,
    datastore text,
    maximum_machines integer NOT NULL,
    project_id uuid,
    development boolean DEFAULT false NOT NULL,
    enabled boolean DEFAULT false NOT NULL
);


ALTER TABLE public.hosts OWNER TO postgres;

--
-- Name: module_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.module_versions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    module_id uuid NOT NULL,
    name text,
    url_link text,
    variables text,
    outputs text,
    date_created timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL
);


ALTER TABLE public.module_versions OWNER TO postgres;

--
-- Name: modules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modules (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text,
    path text,
    description text,
    date_modified timestamp without time zone
);


ALTER TABLE public.modules OWNER TO postgres;

--
-- Name: permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    key text,
    value text,
    description text,
    read_only boolean NOT NULL
);


ALTER TABLE public.permissions OWNER TO postgres;

--
-- Name: plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.plans (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    run_id uuid NOT NULL,
    status integer NOT NULL,
    output text
);


ALTER TABLE public.plans OWNER TO postgres;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: removed_resources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.removed_resources (
    id text NOT NULL
);


ALTER TABLE public.removed_resources OWNER TO postgres;

--
-- Name: runs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.runs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    workspace_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    is_destroy boolean NOT NULL,
    status integer NOT NULL,
    targets text,
    created_by_id uuid,
    modified_at timestamp without time zone,
    modified_by_id uuid
);


ALTER TABLE public.runs OWNER TO postgres;

--
-- Name: user_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    permission_id uuid NOT NULL
);


ALTER TABLE public.user_permissions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: workspaces; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workspaces (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text,
    state text,
    directory_id uuid NOT NULL,
    state_backup text,
    last_synced timestamp without time zone,
    sync_errors text,
    host_id uuid,
    dynamic_host boolean DEFAULT false NOT NULL,
    terraform_version text
);


ALTER TABLE public.workspaces OWNER TO postgres;

--
-- Data for Name: __EFMigrationsHistory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."__EFMigrationsHistory" ("MigrationId", "ProductVersion") FROM stdin;
20190305205350_Initial	3.1.0
20190305205435_Changed_Configuration_File_Content_To_String	3.1.0
20190311162300_Renamed_ConfigurationFile_To_File	3.1.0
20190313171007_Update_Workspace_State	3.1.0
20190313171706_Add_DirectoryId_To_Workspace	3.1.0
20190315151047_Added_Workspace_To_File	3.1.0
20190321164635_Added_Run_Plan_Apply	3.1.0
20190322135944_Updated_RunStatus	3.1.0
20190322151220_Updated_Run_Relationships	3.1.0
20190322195111_Reverted_RunStatus	3.1.0
20190507173545_Added_Targets_To_Run	3.1.0
20190618124545_Added_LastSynced_To_Workspace	3.1.0
20190618131104_Added_Index_To_Run_CreatedAt	3.1.0
20190620191652_Added_RemovedResource	3.1.0
20190621160837_Added_SyncErrors_To_Workspace	3.1.0
20190927233702_terraform_modules	3.1.0
20191002164750_terraform_modules_to_modules	3.1.0
20191002190744_remove_modules_table	3.1.0
20191002191019_modules_and_versions	3.1.0
20191002194840_modules_and_versions_fix	3.1.0
20191004195055_moduleVersions	3.1.0
20191007142114_directory_hierarchy	3.1.0
20191010132816_default_directory_path	3.1.0
20191025164500_UserPermissions	3.1.0
20191025194721_UserPermissionsRemove	3.1.0
20191025194925_UserPermissions2	3.1.0
20191028180521_added_host_hostmachine	3.1.0
20191029111850_UserPermissions3	3.1.0
20191108181742_moduleDateModified	3.1.0
20191111185204_additional_host_fields	3.1.0
20191217134459_FileVersions	3.1.0
20191217210345_FileVersions2	3.1.0
20191218185131_file_locking	3.1.0
20191220195734_TaggedBy	3.1.0
20191223165727_file_administratively_locked	3.1.0
20200421130306_added_date_created_to_module_version	3.1.0
20200508145944_changed_exercise_to_project	3.1.0
20200729205946_added_terraform_version_to_workspace	3.1.0
20200731211309_added_terraform_version_to_directory	3.1.0
20210505162231_added_user_to_run	3.1.0
\.


--
-- Data for Name: applies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.applies (id, run_id, status, output) FROM stdin;
\.


--
-- Data for Name: directories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directories (id, name, project_id, parent_id, path, terraform_version) FROM stdin;
4f45e422-088e-42a0-bbfa-3b9dfc1cc98e	Shared	bae102da-7082-4c0a-a010-e97d3a6c3956	\N	4f45e422-088e-42a0-bbfa-3b9dfc1cc98e/	\N
\.


--
-- Data for Name: file_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.file_versions (id, file_id, name, modified_by_id, content, date_saved, tag, date_tagged, tagged_by_id) FROM stdin;
\.


--
-- Data for Name: files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.files (id, name, directory_id, content, workspace_id, date_saved, is_deleted, modified_by_id, locked_by_id, administratively_locked) FROM stdin;
67528aa9-54ef-4846-ad04-16eee4181d30	variables.tf	4f45e422-088e-42a0-bbfa-3b9dfc1cc98e	variable datacenter {}\nvariable cluster {}\nvariable dvswitch {}\nvariable vsphere_datastore {}\nvariable iso_datastore {}\nvariable ubuntu_template {}\nvariable folder {\n    default = ""\n}\nvariable view_id {\n    default = "unique"\n}\nvariable admin {\n    default = "e6207d5c-6c2b-4634-8ecf-bf2325ba7ec7"\n}\nvariable blue {\n    default = "8b78629b-1b2b-4d06-9c4b-70c326bc5e40"\n}\nvariable default_network {}\n	\N	2021-12-01 18:16:25.893021	f	dee684c5-2eaf-401a-915b-d3d4320fe5d5	\N	f
6ecf9dfd-e625-4430-a002-0a91a8f48947	networking.tf	4f45e422-088e-42a0-bbfa-3b9dfc1cc98e	\nmodule "distributed-port-group" {\n  source = "git::https://gitlab.$DOMAIN/caster-modules/distributed-port-group.git?ref=v0.0.1"\n  dc_id = module.infrastructure.dc.id\n  cluster_id = module.infrastructure.cluster.id\n  dvswitch_id = module.infrastructure.dvswitch[0].id\n  portgroups = {\n        "${var.default_network}-${var.view_id}": {\n          "cidr": "192.168.1.0/24",\n          "vlan": "0"\n        }\n      }\n}\n	\N	2021-12-02 03:29:05.179604	f	dee684c5-2eaf-401a-915b-d3d4320fe5d5	\N	f
e56a6924-66da-472e-86f2-252adb315c88	infrastructure.tf	4f45e422-088e-42a0-bbfa-3b9dfc1cc98e	\nmodule "infrastructure" {\n  source = "git::https://gitlab.$DOMAIN/caster-modules/infrastructure.git?ref=v0.0.3"\n  vsphere_datacenter = "${var.datacenter}"\n  vsphere_cluster = "${var.cluster}"\n  vsphere_dvswitch = "${var.dvswitch}"\n  vsphere_datastore = "${var.vsphere_datastore}"\n  vsphere_folder = var.folder\n}\n	\N	2021-12-02 03:28:19.475365	f	dee684c5-2eaf-401a-915b-d3d4320fe5d5	\N	f
0b18d28f-ff17-4a93-8566-896064c088c4	machines.tf	4f45e422-088e-42a0-bbfa-3b9dfc1cc98e	module "vm-generic" {\n  source = "git::https://gitlab.$DOMAIN/caster-modules/vm-generic.git?ref=v0.0.4"\n  vmname = "ubuntu-${var.view_id}"\n  dc = module.infrastructure.dc.name\n  datastore = module.infrastructure.datastore.name\n  vmfolder = ""\n  vmrp = ""\n  vm_depends_on = [module.infrastructure]\n  network_depends_on = [module.distributed-port-group] \n  vmrp_id = module.infrastructure.cluster.resource_pool_id\n  network_cards = [module.distributed-port-group.portgroups["${var.default_network}-${var.view_id}"].name]\n  vmtemp = var.ubuntu_template\n  cpu_number = 4\n  ram_size = 1024\n  iso_datastore = var.iso_datastore\n  iso_paths = {\n        "path": "/"\n      }\n  \n  extra_config = {\n    "guestinfo.team_id" = "${var.admin},${var.blue}"\n      }\n}\n	\N	2021-12-02 03:28:50.223232	f	dee684c5-2eaf-401a-915b-d3d4320fe5d5	\N	f
701474b8-80c7-480e-ba2e-25d3cc516aae	variables.auto.tfvars	4f45e422-088e-42a0-bbfa-3b9dfc1cc98e	datacenter = "$VSPHERE_DATACENTER"\n# Cluster needs to match VSPHERE_CLUSTER Environment variable\ncluster = "$VSPHERE_CLUSTER"\ndvswitch = "$VSPHERE_DV_SWITCH"\nvsphere_datastore = "$VSPHERE_DATASTORE"\niso_datastore = "$VSPHERE_ISO_DATASTORE"\n# Must have a snapshot\nubuntu_template = "$UBUNTU_TEMPLATE"\nfolder = "$VSPHERE_DATACENTER/vm"\ndefault_network = "terraform-default"\n	\N	2021-12-02 03:27:58.344623	f	dee684c5-2eaf-401a-915b-d3d4320fe5d5	\N	f
\.


--
-- Data for Name: host_machines; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.host_machines (id, name, workspace_id, host_id) FROM stdin;
\.


--
-- Data for Name: hosts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hosts (id, name, datastore, maximum_machines, project_id, development, enabled) FROM stdin;
\.


--
-- Data for Name: module_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.module_versions (id, module_id, name, url_link, variables, outputs, date_created) FROM stdin;
\.


--
-- Data for Name: modules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modules (id, name, path, description, date_modified) FROM stdin;
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permissions (id, key, value, description, read_only) FROM stdin;
00000000-0000-0000-0000-000000000001	SystemAdmin	true	Has Full Rights.  Can do everything.	t
00000000-0000-0000-0000-000000000002	ContentDeveloper	true	Can create/edit/delete an Exercise/Directory/Workspace/File/Module	t
\.


--
-- Data for Name: plans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.plans (id, run_id, status, output) FROM stdin;
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, name) FROM stdin;
bae102da-7082-4c0a-a010-e97d3a6c3956	Example Project
\.


--
-- Data for Name: removed_resources; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.removed_resources (id) FROM stdin;
\.


--
-- Data for Name: runs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.runs (id, workspace_id, created_at, is_destroy, status, targets, created_by_id, modified_at, modified_by_id) FROM stdin;
\.


--
-- Data for Name: user_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_permissions (id, user_id, permission_id) FROM stdin;
c0164b19-e522-4ad5-903c-e87a362c59f2	dee684c5-2eaf-401a-915b-d3d4320fe5d5	00000000-0000-0000-0000-000000000001
0405258f-3d33-4049-b1b3-d35eb03ed7d3	32c11441-7eec-47eb-a915-607c4f2529f4	00000000-0000-0000-0000-000000000001
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name) FROM stdin;
3b680d97-6d0b-44c9-8cc7-fd10ea79c2a6	crucible-admin@crucible.io
dee684c5-2eaf-401a-915b-d3d4320fe5d5	Administrator
32c11441-7eec-47eb-a915-607c4f2529f4	crucible-admin@crucible.io
\.


--
-- Data for Name: workspaces; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workspaces (id, name, state, directory_id, state_backup, last_synced, sync_errors, host_id, dynamic_host, terraform_version) FROM stdin;
a1259e68-1c98-4899-8c7e-0517e43408ff	Example	\N	4f45e422-088e-42a0-bbfa-3b9dfc1cc98e	\N	\N	\N	\N	f	0.14.0
\.


--
-- Name: __EFMigrationsHistory PK___EFMigrationsHistory; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."__EFMigrationsHistory"
    ADD CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId");


--
-- Name: applies PK_applies; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.applies
    ADD CONSTRAINT "PK_applies" PRIMARY KEY (id);


--
-- Name: directories PK_directories; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directories
    ADD CONSTRAINT "PK_directories" PRIMARY KEY (id);


--
-- Name: projects PK_exercises; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT "PK_exercises" PRIMARY KEY (id);


--
-- Name: file_versions PK_file_versions; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_versions
    ADD CONSTRAINT "PK_file_versions" PRIMARY KEY (id);


--
-- Name: files PK_files; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT "PK_files" PRIMARY KEY (id);


--
-- Name: host_machines PK_host_machines; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.host_machines
    ADD CONSTRAINT "PK_host_machines" PRIMARY KEY (id);


--
-- Name: hosts PK_hosts; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hosts
    ADD CONSTRAINT "PK_hosts" PRIMARY KEY (id);


--
-- Name: module_versions PK_module_versions; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.module_versions
    ADD CONSTRAINT "PK_module_versions" PRIMARY KEY (id);


--
-- Name: modules PK_modules; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT "PK_modules" PRIMARY KEY (id);


--
-- Name: permissions PK_permissions; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT "PK_permissions" PRIMARY KEY (id);


--
-- Name: plans PK_plans; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT "PK_plans" PRIMARY KEY (id);


--
-- Name: removed_resources PK_removed_resources; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.removed_resources
    ADD CONSTRAINT "PK_removed_resources" PRIMARY KEY (id);


--
-- Name: runs PK_runs; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.runs
    ADD CONSTRAINT "PK_runs" PRIMARY KEY (id);


--
-- Name: user_permissions PK_user_permissions; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT "PK_user_permissions" PRIMARY KEY (id);


--
-- Name: users PK_users; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "PK_users" PRIMARY KEY (id);


--
-- Name: workspaces PK_workspaces; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workspaces
    ADD CONSTRAINT "PK_workspaces" PRIMARY KEY (id);


--
-- Name: IX_applies_run_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IX_applies_run_id" ON public.applies USING btree (run_id);


--
-- Name: IX_directories_parent_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_directories_parent_id" ON public.directories USING btree (parent_id);


--
-- Name: IX_directories_path; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_directories_path" ON public.directories USING btree (path);


--
-- Name: IX_directories_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_directories_project_id" ON public.directories USING btree (project_id);


--
-- Name: IX_file_versions_file_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_file_versions_file_id" ON public.file_versions USING btree (file_id);


--
-- Name: IX_file_versions_modified_by_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_file_versions_modified_by_id" ON public.file_versions USING btree (modified_by_id);


--
-- Name: IX_file_versions_tagged_by_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_file_versions_tagged_by_id" ON public.file_versions USING btree (tagged_by_id);


--
-- Name: IX_files_directory_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_files_directory_id" ON public.files USING btree (directory_id);


--
-- Name: IX_files_locked_by_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_files_locked_by_id" ON public.files USING btree (locked_by_id);


--
-- Name: IX_files_modified_by_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_files_modified_by_id" ON public.files USING btree (modified_by_id);


--
-- Name: IX_files_workspace_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_files_workspace_id" ON public.files USING btree (workspace_id);


--
-- Name: IX_host_machines_host_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_host_machines_host_id" ON public.host_machines USING btree (host_id);


--
-- Name: IX_host_machines_workspace_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_host_machines_workspace_id" ON public.host_machines USING btree (workspace_id);


--
-- Name: IX_hosts_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_hosts_project_id" ON public.hosts USING btree (project_id);


--
-- Name: IX_module_versions_module_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_module_versions_module_id" ON public.module_versions USING btree (module_id);


--
-- Name: IX_permissions_key_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IX_permissions_key_value" ON public.permissions USING btree (key, value);


--
-- Name: IX_plans_run_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IX_plans_run_id" ON public.plans USING btree (run_id);


--
-- Name: IX_runs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_runs_created_at" ON public.runs USING btree (created_at);


--
-- Name: IX_runs_created_by_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_runs_created_by_id" ON public.runs USING btree (created_by_id);


--
-- Name: IX_runs_modified_by_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_runs_modified_by_id" ON public.runs USING btree (modified_by_id);


--
-- Name: IX_runs_workspace_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_runs_workspace_id" ON public.runs USING btree (workspace_id);


--
-- Name: IX_user_permissions_permission_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_user_permissions_permission_id" ON public.user_permissions USING btree (permission_id);


--
-- Name: IX_user_permissions_user_id_permission_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IX_user_permissions_user_id_permission_id" ON public.user_permissions USING btree (user_id, permission_id);


--
-- Name: IX_workspaces_directory_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_workspaces_directory_id" ON public.workspaces USING btree (directory_id);


--
-- Name: IX_workspaces_host_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IX_workspaces_host_id" ON public.workspaces USING btree (host_id);


--
-- Name: applies FK_applies_runs_run_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.applies
    ADD CONSTRAINT "FK_applies_runs_run_id" FOREIGN KEY (run_id) REFERENCES public.runs(id) ON DELETE CASCADE;


--
-- Name: directories FK_directories_directories_parent_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directories
    ADD CONSTRAINT "FK_directories_directories_parent_id" FOREIGN KEY (parent_id) REFERENCES public.directories(id) ON DELETE CASCADE;


--
-- Name: directories FK_directories_projects_project_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directories
    ADD CONSTRAINT "FK_directories_projects_project_id" FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: file_versions FK_file_versions_files_file_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_versions
    ADD CONSTRAINT "FK_file_versions_files_file_id" FOREIGN KEY (file_id) REFERENCES public.files(id) ON DELETE CASCADE;


--
-- Name: file_versions FK_file_versions_users_modified_by_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_versions
    ADD CONSTRAINT "FK_file_versions_users_modified_by_id" FOREIGN KEY (modified_by_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: file_versions FK_file_versions_users_tagged_by_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_versions
    ADD CONSTRAINT "FK_file_versions_users_tagged_by_id" FOREIGN KEY (tagged_by_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: files FK_files_directories_directory_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT "FK_files_directories_directory_id" FOREIGN KEY (directory_id) REFERENCES public.directories(id) ON DELETE CASCADE;


--
-- Name: files FK_files_users_locked_by_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT "FK_files_users_locked_by_id" FOREIGN KEY (locked_by_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: files FK_files_users_modified_by_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT "FK_files_users_modified_by_id" FOREIGN KEY (modified_by_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: files FK_files_workspaces_workspace_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT "FK_files_workspaces_workspace_id" FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: host_machines FK_host_machines_hosts_host_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.host_machines
    ADD CONSTRAINT "FK_host_machines_hosts_host_id" FOREIGN KEY (host_id) REFERENCES public.hosts(id) ON DELETE CASCADE;


--
-- Name: host_machines FK_host_machines_workspaces_workspace_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.host_machines
    ADD CONSTRAINT "FK_host_machines_workspaces_workspace_id" FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: hosts FK_hosts_projects_project_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hosts
    ADD CONSTRAINT "FK_hosts_projects_project_id" FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE RESTRICT;


--
-- Name: module_versions FK_module_versions_modules_module_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.module_versions
    ADD CONSTRAINT "FK_module_versions_modules_module_id" FOREIGN KEY (module_id) REFERENCES public.modules(id) ON DELETE CASCADE;


--
-- Name: plans FK_plans_runs_run_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT "FK_plans_runs_run_id" FOREIGN KEY (run_id) REFERENCES public.runs(id) ON DELETE CASCADE;


--
-- Name: runs FK_runs_users_created_by_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.runs
    ADD CONSTRAINT "FK_runs_users_created_by_id" FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: runs FK_runs_users_modified_by_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.runs
    ADD CONSTRAINT "FK_runs_users_modified_by_id" FOREIGN KEY (modified_by_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: runs FK_runs_workspaces_workspace_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.runs
    ADD CONSTRAINT "FK_runs_workspaces_workspace_id" FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: user_permissions FK_user_permissions_permissions_permission_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT "FK_user_permissions_permissions_permission_id" FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: user_permissions FK_user_permissions_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT "FK_user_permissions_users_user_id" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: workspaces FK_workspaces_directories_directory_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workspaces
    ADD CONSTRAINT "FK_workspaces_directories_directory_id" FOREIGN KEY (directory_id) REFERENCES public.directories(id) ON DELETE CASCADE;


--
-- Name: workspaces FK_workspaces_hosts_host_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workspaces
    ADD CONSTRAINT "FK_workspaces_hosts_host_id" FOREIGN KEY (host_id) REFERENCES public.hosts(id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

