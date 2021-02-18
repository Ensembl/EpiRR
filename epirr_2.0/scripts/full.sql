





SELECT 
 project.name AS project_name,
 dataset_id,
 dataset.accession AS ds_accession,
 dataset.created AS ds_created,
 dsv.dataset_version_id,
 dsv.version AS dsv_version,
 dsv.is_current,
 dsv.description,
 dsv.full_accession,
 dsv.created AS dsv_created,
 type.name as type_name,
 status.name as status_name,
 rd.raw_data_id,
 rd.primary_accession,
 rd.secondary_accession,
 rd.assay_type,
 rd.experiment_type,
 archive.name as archive_name
FROM dataset 
JOIN project USING (project_id) 
JOIN dataset_version dsv USING(dataset_id) 
JOIN type USING (type_id) 
JOIN status USING (status_id) 
JOIN raw_data rd USING (dataset_version_id)
JOIN archive USING (archive_id)
limit 5;


 rmd.name AS raw_meta_data_name,
 rmd.value AS raw_meta_data_value
 GROUP_CONCAT( CONCAT( meta_data.name, ':', meta_data.value) SEPARATOR ';' ) AS 'metadata_name:value',
JOIN meta_data USING (dataset_version_id)
JOIN raw_meta_data rmd USING (raw_data_id)
