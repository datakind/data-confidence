-- Malaria testing and treatment, flagging oddities 
-- Notebook: MT-Misalignment Detection - Assessing Flow of Malaria Testing (Feb Data)
with malaria_testing_errors as (
Select a.uuid, a.reported_by, a.patient_uuid,
    (CASE WHEN a.mrdt_result in (NULL, 'not_done','negative') 
            AND a.malaria_al_treatment_given = 'yes' then 1
          WHEN a.mrdt_result = 'not_done' AND a.reason_no_mrdt is NULL then 1
          WHEN a.malaria_al_treatment_given != 'yes' 
                AND a.c_malaria_important_instruction in ('Help the caregiver give the first dose now.','Advise caregiver to give 2nd dose of AL after 8 hrs and to give does twice daily for 2 more days.')
                AND a.new_age <= 5 then 1
          WHEN a.mrdt_result = 'not_done' and a.reason_no_mrdt is NULL then 1
          WHEN a.mrdt_result = 'positive' AND a.malaria_al_treatment_given in ('no', NULL)
                AND a.c_malaria_important_instruction in ('Help the caregiver give the first dose now.','Advise caregiver to give 2nd dose of AL after 8 hrs and to give does twice daily for 2 more days.')
                AND a.new_age <= 5 then 1
          else 0 end) as error_flag,
    
    (CASE WHEN a.mrdt_result in (NULL, 'not_done','negative') 
            AND a.malaria_al_treatment_given = 'yes' then 'Check result & treatment columns'
          WHEN a.mrdt_result = 'not_done' AND a.reason_no_mrdt is NULL then 'Give reason why treatment was not performed'
          WHEN a.malaria_al_treatment_given != 'yes' 
                AND a.c_malaria_important_instruction in ('Help the caregiver give the first dose now.','Advise caregiver to give 2nd dose of AL after 8 hrs and to give does twice daily for 2 more days.')
                AND a.new_age <= 5 then 'No medication given but instruction written'
          WHEN a.mrdt_result = 'not_done' and a.reason_no_mrdt is NULL then 'Test not done without reason of why'          
          WHEN a.mrdt_result = 'positive' AND a.malaria_al_treatment_given in ('no', NULL)
                AND a.c_malaria_important_instruction in ('Help the caregiver give the first dose now.','Advise caregiver to give 2nd dose of AL after 8 hrs and to give does twice daily for 2 more days.')
                AND a.new_age <= 5 then 'Positive test but treatment marked as not needed'
          else 'No issues' end) as error_reason

    from ( SELECT b.*,
             CAST((CASE WHEN b.c_patient_age LIKE '% years old' THEN TRIM(TRAILING ' years old' FROM b.c_patient_age)
                  ELSE '0' END) as INTEGER) as new_age
    FROM {{ ref('assessment') }} b
         ) a 
)

Select *
from malaria_testing_errors
WHERE error_flag = 1