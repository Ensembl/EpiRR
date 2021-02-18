--
-- PostgreSQL database dump
--

-- Dumped from database version 13.1
-- Dumped by pg_dump version 13.1

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
-- Name: trigger_set_timestamp(); Type: FUNCTION; Schema: public; Owner: juettema
--

CREATE FUNCTION public.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


ALTER FUNCTION public.trigger_set_timestamp() OWNER TO juettema;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: archive; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.archive (
    archive_id integer NOT NULL,
    name character varying NOT NULL,
    full_name character varying,
    url character varying,
    base_url character varying
);


ALTER TABLE public.archive OWNER TO juettema;

--
-- Name: archive_archive_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.archive_archive_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.archive_archive_id_seq OWNER TO juettema;

--
-- Name: archive_archive_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: juettema
--

ALTER SEQUENCE public.archive_archive_id_seq OWNED BY public.archive.archive_id;


--
-- Name: epigenome; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.epigenome (
    epigenome_id integer NOT NULL,
    accession character varying NOT NULL,
    description text,
    project_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.epigenome OWNER TO juettema;

--
-- Name: epigenome_epigenome_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.epigenome_epigenome_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.epigenome_epigenome_id_seq OWNER TO juettema;

--
-- Name: epigenome_epigenome_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: juettema
--

ALTER SEQUENCE public.epigenome_epigenome_id_seq OWNED BY public.epigenome.epigenome_id;


--
-- Name: epigenome_version_experiment; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.epigenome_version_experiment (
    epigenome_experiment_id integer NOT NULL,
    epigenome_version_id integer NOT NULL,
    experiment_id integer NOT NULL
);


ALTER TABLE public.epigenome_version_experiment OWNER TO juettema;

--
-- Name: epigenome_experiment_epigenome_experiment_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.epigenome_experiment_epigenome_experiment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.epigenome_experiment_epigenome_experiment_id_seq OWNER TO juettema;

--
-- Name: epigenome_experiment_epigenome_experiment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: juettema
--

ALTER SEQUENCE public.epigenome_experiment_epigenome_experiment_id_seq OWNED BY public.epigenome_version_experiment.epigenome_experiment_id;


--
-- Name: experiment_version_experiment_version_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.experiment_version_experiment_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.experiment_version_experiment_version_id_seq OWNER TO juettema;

--
-- Name: epigenome_version; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.epigenome_version (
    epigenome_version_id integer DEFAULT nextval('public.experiment_version_experiment_version_id_seq'::regclass) NOT NULL,
    epigenome_id integer NOT NULL,
    full_accession character varying(20) NOT NULL,
    version integer NOT NULL,
    is_current integer NOT NULL,
    status_id integer NOT NULL,
    ihec_version_id integer DEFAULT 1 NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.epigenome_version OWNER TO juettema;

--
-- Name: experiment; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.experiment (
    experiment_id integer NOT NULL,
    accession character varying NOT NULL,
    secondary_accession character varying,
    archive_id integer,
    library_strategy_id integer NOT NULL,
    experiment_type_id integer NOT NULL,
    ihec_version_id integer DEFAULT 1,
    uri character varying,
    xml xml,
    md5sum uuid,
    validator_report jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.experiment OWNER TO juettema;

--
-- Name: TABLE experiment; Type: COMMENT; Schema: public; Owner: juettema
--

COMMENT ON TABLE public.experiment IS 'Funcgen Experiment';


--
-- Name: experiment_experiment_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.experiment_experiment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.experiment_experiment_id_seq OWNER TO juettema;

--
-- Name: experiment_experiment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: juettema
--

ALTER SEQUENCE public.experiment_experiment_id_seq OWNED BY public.experiment.experiment_id;


--
-- Name: experiment_metadata_experiment_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.experiment_metadata_experiment_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.experiment_metadata_experiment_metadata_id_seq OWNER TO juettema;

--
-- Name: experiment_metadata; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.experiment_metadata (
    experiment_metadata_id integer DEFAULT nextval('public.experiment_metadata_experiment_metadata_id_seq'::regclass) NOT NULL,
    experiment_id integer NOT NULL,
    key character varying(255) NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.experiment_metadata OWNER TO postgres;

--
-- Name: experiment_sample_experiment_sample_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.experiment_sample_experiment_sample_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.experiment_sample_experiment_sample_id_seq OWNER TO juettema;

--
-- Name: experiment_sample; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.experiment_sample (
    experiment_sample_id integer DEFAULT nextval('public.experiment_sample_experiment_sample_id_seq'::regclass) NOT NULL,
    experiment_id integer,
    sample_id integer
);


ALTER TABLE public.experiment_sample OWNER TO juettema;

--
-- Name: experiment_type; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.experiment_type (
    experiment_type_id integer NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.experiment_type OWNER TO juettema;

--
-- Name: experiment_type_experiment_type_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.experiment_type_experiment_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.experiment_type_experiment_type_id_seq OWNER TO juettema;

--
-- Name: ihec_version_ihec_version_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.ihec_version_ihec_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.ihec_version_ihec_version_id_seq OWNER TO juettema;

--
-- Name: ihec_version; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.ihec_version (
    ihec_version_id integer DEFAULT nextval('public.ihec_version_ihec_version_id_seq'::regclass) NOT NULL,
    version numeric(6,3) NOT NULL,
    url character varying
);


ALTER TABLE public.ihec_version OWNER TO juettema;

--
-- Name: library_strategy_library_strategy_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.library_strategy_library_strategy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.library_strategy_library_strategy_id_seq OWNER TO juettema;

--
-- Name: library_strategy; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.library_strategy (
    library_strategy_id integer DEFAULT nextval('public.library_strategy_library_strategy_id_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.library_strategy OWNER TO juettema;

--
-- Name: project; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.project (
    project_id integer NOT NULL,
    name character varying NOT NULL,
    url character varying NOT NULL
);


ALTER TABLE public.project OWNER TO juettema;

--
-- Name: project_project_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.project_project_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_project_id_seq OWNER TO juettema;

--
-- Name: project_project_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: juettema
--

ALTER SEQUENCE public.project_project_id_seq OWNED BY public.project.project_id;


--
-- Name: sample; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.sample (
    sample_id integer NOT NULL,
    accession character varying NOT NULL,
    ihec_version_id integer DEFAULT 1,
    xml xml,
    uri character varying,
    md5sum uuid,
    validator_report jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.sample OWNER TO juettema;

--
-- Name: sample_metadata_sample_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.sample_metadata_sample_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.sample_metadata_sample_metadata_id_seq OWNER TO juettema;

--
-- Name: sample_metadata; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.sample_metadata (
    sample_metadata_id integer DEFAULT nextval('public.sample_metadata_sample_metadata_id_seq'::regclass) NOT NULL,
    sample_id integer NOT NULL,
    key character varying(255) NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.sample_metadata OWNER TO juettema;

--
-- Name: sample_sample_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.sample_sample_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sample_sample_id_seq OWNER TO juettema;

--
-- Name: sample_sample_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: juettema
--

ALTER SEQUENCE public.sample_sample_id_seq OWNED BY public.sample.sample_id;


--
-- Name: status_status_id_seq; Type: SEQUENCE; Schema: public; Owner: juettema
--

CREATE SEQUENCE public.status_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.status_status_id_seq OWNER TO juettema;

--
-- Name: status; Type: TABLE; Schema: public; Owner: juettema
--

CREATE TABLE public.status (
    status_id integer DEFAULT nextval('public.status_status_id_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.status OWNER TO juettema;

--
-- Name: view_experiment_to_sample; Type: VIEW; Schema: public; Owner: juettema
--

CREATE VIEW public.view_experiment_to_sample AS
 SELECT experiment.accession AS experiment__accession,
    experiment.experiment_id AS experiment__experiment_id,
    btrim((xpath('EXPERIMENT_SET/EXPERIMENT/DESIGN/SAMPLE_DESCRIPTOR/@accession'::text, experiment.xml))::text, '{}'::text) AS sample__experiment
   FROM public.experiment
  WHERE (experiment.xml IS NOT NULL);


ALTER TABLE public.view_experiment_to_sample OWNER TO juettema;

--
-- Name: archive archive_id; Type: DEFAULT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.archive ALTER COLUMN archive_id SET DEFAULT nextval('public.archive_archive_id_seq'::regclass);


--
-- Name: epigenome epigenome_id; Type: DEFAULT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome ALTER COLUMN epigenome_id SET DEFAULT nextval('public.epigenome_epigenome_id_seq'::regclass);


--
-- Name: epigenome_version_experiment epigenome_experiment_id; Type: DEFAULT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome_version_experiment ALTER COLUMN epigenome_experiment_id SET DEFAULT nextval('public.epigenome_experiment_epigenome_experiment_id_seq'::regclass);


--
-- Name: experiment experiment_id; Type: DEFAULT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment ALTER COLUMN experiment_id SET DEFAULT nextval('public.experiment_experiment_id_seq'::regclass);


--
-- Name: project project_id; Type: DEFAULT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.project ALTER COLUMN project_id SET DEFAULT nextval('public.project_project_id_seq'::regclass);


--
-- Name: sample sample_id; Type: DEFAULT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.sample ALTER COLUMN sample_id SET DEFAULT nextval('public.sample_sample_id_seq'::regclass);


--
-- Name: archive archive_name_unique; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.archive
    ADD CONSTRAINT archive_name_unique UNIQUE (name);


--
-- Name: archive archive_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.archive
    ADD CONSTRAINT archive_pkey PRIMARY KEY (archive_id);


--
-- Name: epigenome_version_experiment epigenome_experiment_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome_version_experiment
    ADD CONSTRAINT epigenome_experiment_pkey PRIMARY KEY (epigenome_experiment_id);


--
-- Name: epigenome epigenome_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome
    ADD CONSTRAINT epigenome_pkey PRIMARY KEY (epigenome_id);


--
-- Name: epigenome_version epigenome_version_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome_version
    ADD CONSTRAINT epigenome_version_pkey PRIMARY KEY (epigenome_version_id);


--
-- Name: experiment_metadata experiment_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.experiment_metadata
    ADD CONSTRAINT experiment_metadata_pkey PRIMARY KEY (experiment_metadata_id);


--
-- Name: experiment experiment_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment
    ADD CONSTRAINT experiment_pkey PRIMARY KEY (experiment_id);


--
-- Name: experiment_sample experiment_sample_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment_sample
    ADD CONSTRAINT experiment_sample_pkey PRIMARY KEY (experiment_sample_id);


--
-- Name: experiment_type experiment_type_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment_type
    ADD CONSTRAINT experiment_type_pkey PRIMARY KEY (experiment_type_id);


--
-- Name: ihec_version ihec_version_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.ihec_version
    ADD CONSTRAINT ihec_version_pkey PRIMARY KEY (ihec_version_id);


--
-- Name: library_strategy library_strategy_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.library_strategy
    ADD CONSTRAINT library_strategy_pkey PRIMARY KEY (library_strategy_id);


--
-- Name: project project_name_key; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_name_key UNIQUE (name);


--
-- Name: project project_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (project_id);


--
-- Name: sample_metadata sample_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.sample_metadata
    ADD CONSTRAINT sample_metadata_pkey PRIMARY KEY (sample_metadata_id);


--
-- Name: sample sample_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.sample
    ADD CONSTRAINT sample_pkey PRIMARY KEY (sample_id);


--
-- Name: status status_pkey; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (status_id);


--
-- Name: library_strategy uc_assay_type_name; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.library_strategy
    ADD CONSTRAINT uc_assay_type_name UNIQUE (name);


--
-- Name: epigenome uc_epigenome_ihec_accession; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome
    ADD CONSTRAINT uc_epigenome_ihec_accession UNIQUE (accession);


--
-- Name: experiment uc_experiment_accession; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment
    ADD CONSTRAINT uc_experiment_accession UNIQUE (accession);


--
-- Name: experiment uc_experiment_md5sum; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment
    ADD CONSTRAINT uc_experiment_md5sum UNIQUE (md5sum);


--
-- Name: experiment_metadata uc_experiment_metadata_key_value; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.experiment_metadata
    ADD CONSTRAINT uc_experiment_metadata_key_value UNIQUE (experiment_id, key, value);


--
-- Name: sample uc_sample_accession; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.sample
    ADD CONSTRAINT uc_sample_accession UNIQUE (accession);


--
-- Name: sample_metadata uc_sample_metadata_key_value; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.sample_metadata
    ADD CONSTRAINT uc_sample_metadata_key_value UNIQUE (sample_id, key, value);


--
-- Name: status uc_status_name; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT uc_status_name UNIQUE (name);


--
-- Name: experiment_sample uq_assay_id_biosample_id; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment_sample
    ADD CONSTRAINT uq_assay_id_biosample_id UNIQUE (experiment_id, sample_id);


--
-- Name: epigenome_version_experiment uq_epigenome_id_experiment_id; Type: CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome_version_experiment
    ADD CONSTRAINT uq_epigenome_id_experiment_id UNIQUE (epigenome_version_id, experiment_id);


--
-- Name: fki_fk_assay_type_id; Type: INDEX; Schema: public; Owner: juettema
--

CREATE INDEX fki_fk_assay_type_id ON public.experiment USING btree (library_strategy_id);


--
-- Name: fki_fk_epigenome_id; Type: INDEX; Schema: public; Owner: juettema
--

CREATE INDEX fki_fk_epigenome_id ON public.epigenome_version USING btree (epigenome_id);


--
-- Name: fki_fk_epigenome_version_id; Type: INDEX; Schema: public; Owner: juettema
--

CREATE INDEX fki_fk_epigenome_version_id ON public.epigenome_version_experiment USING btree (epigenome_version_id);


--
-- Name: fki_fk_experiment_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_fk_experiment_id ON public.experiment_metadata USING btree (experiment_id);


--
-- Name: fki_fk_experiment_type_id; Type: INDEX; Schema: public; Owner: juettema
--

CREATE INDEX fki_fk_experiment_type_id ON public.experiment USING btree (experiment_type_id);


--
-- Name: fki_fk_ihec_version_id_egv; Type: INDEX; Schema: public; Owner: juettema
--

CREATE INDEX fki_fk_ihec_version_id_egv ON public.epigenome_version USING btree (ihec_version_id);


--
-- Name: fki_fk_ihec_version_id_exp; Type: INDEX; Schema: public; Owner: juettema
--

CREATE INDEX fki_fk_ihec_version_id_exp ON public.experiment USING btree (ihec_version_id);


--
-- Name: fki_fk_ihec_version_id_sample; Type: INDEX; Schema: public; Owner: juettema
--

CREATE INDEX fki_fk_ihec_version_id_sample ON public.sample USING btree (ihec_version_id);


--
-- Name: fki_fk_project_id; Type: INDEX; Schema: public; Owner: juettema
--

CREATE INDEX fki_fk_project_id ON public.epigenome USING btree (project_id);


--
-- Name: fki_fk_sample_id; Type: INDEX; Schema: public; Owner: juettema
--

CREATE INDEX fki_fk_sample_id ON public.sample_metadata USING btree (sample_id);


--
-- Name: fki_fk_status_id; Type: INDEX; Schema: public; Owner: juettema
--

CREATE INDEX fki_fk_status_id ON public.epigenome_version USING btree (status_id);


--
-- Name: epigenome set_timestamp; Type: TRIGGER; Schema: public; Owner: juettema
--

CREATE TRIGGER set_timestamp BEFORE UPDATE ON public.epigenome FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: epigenome_version set_timestamp; Type: TRIGGER; Schema: public; Owner: juettema
--

CREATE TRIGGER set_timestamp BEFORE UPDATE ON public.epigenome_version FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: experiment set_timestamp; Type: TRIGGER; Schema: public; Owner: juettema
--

CREATE TRIGGER set_timestamp BEFORE UPDATE ON public.experiment FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: sample set_timestamp; Type: TRIGGER; Schema: public; Owner: juettema
--

CREATE TRIGGER set_timestamp BEFORE UPDATE ON public.sample FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: experiment fk_archive_id; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment
    ADD CONSTRAINT fk_archive_id FOREIGN KEY (archive_id) REFERENCES public.archive(archive_id) NOT VALID;


--
-- Name: experiment_sample fk_assay_id; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment_sample
    ADD CONSTRAINT fk_assay_id FOREIGN KEY (experiment_id) REFERENCES public.experiment(experiment_id);


--
-- Name: experiment_sample fk_biosample_id; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment_sample
    ADD CONSTRAINT fk_biosample_id FOREIGN KEY (sample_id) REFERENCES public.sample(sample_id);


--
-- Name: epigenome_version fk_epigenome_id; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome_version
    ADD CONSTRAINT fk_epigenome_id FOREIGN KEY (epigenome_id) REFERENCES public.epigenome(epigenome_id) NOT VALID;


--
-- Name: epigenome_version_experiment fk_epigenome_version_id; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome_version_experiment
    ADD CONSTRAINT fk_epigenome_version_id FOREIGN KEY (epigenome_version_id) REFERENCES public.epigenome_version(epigenome_version_id) NOT VALID;


--
-- Name: epigenome_version_experiment fk_experiment_id; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome_version_experiment
    ADD CONSTRAINT fk_experiment_id FOREIGN KEY (experiment_id) REFERENCES public.experiment(experiment_id);


--
-- Name: experiment_metadata fk_experiment_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.experiment_metadata
    ADD CONSTRAINT fk_experiment_id FOREIGN KEY (experiment_id) REFERENCES public.experiment(experiment_id) NOT VALID;


--
-- Name: experiment fk_experiment_type_id; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment
    ADD CONSTRAINT fk_experiment_type_id FOREIGN KEY (experiment_type_id) REFERENCES public.experiment_type(experiment_type_id) NOT VALID;


--
-- Name: epigenome_version fk_ihec_version_id_egv; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome_version
    ADD CONSTRAINT fk_ihec_version_id_egv FOREIGN KEY (ihec_version_id) REFERENCES public.ihec_version(ihec_version_id) NOT VALID;


--
-- Name: experiment fk_ihec_version_id_exp; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment
    ADD CONSTRAINT fk_ihec_version_id_exp FOREIGN KEY (ihec_version_id) REFERENCES public.ihec_version(ihec_version_id) NOT VALID;


--
-- Name: sample fk_ihec_version_id_sample; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.sample
    ADD CONSTRAINT fk_ihec_version_id_sample FOREIGN KEY (ihec_version_id) REFERENCES public.ihec_version(ihec_version_id) NOT VALID;


--
-- Name: experiment fk_library_strategy_id; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.experiment
    ADD CONSTRAINT fk_library_strategy_id FOREIGN KEY (library_strategy_id) REFERENCES public.library_strategy(library_strategy_id) NOT VALID;


--
-- Name: epigenome fk_project_id; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome
    ADD CONSTRAINT fk_project_id FOREIGN KEY (project_id) REFERENCES public.project(project_id) NOT VALID;


--
-- Name: sample_metadata fk_sample_id; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.sample_metadata
    ADD CONSTRAINT fk_sample_id FOREIGN KEY (sample_id) REFERENCES public.sample(sample_id) NOT VALID;


--
-- Name: epigenome_version fk_status_id; Type: FK CONSTRAINT; Schema: public; Owner: juettema
--

ALTER TABLE ONLY public.epigenome_version
    ADD CONSTRAINT fk_status_id FOREIGN KEY (status_id) REFERENCES public.status(status_id) NOT VALID;


--
-- PostgreSQL database dump complete
--

