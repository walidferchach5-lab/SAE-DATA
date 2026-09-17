-- =====================================================================
--  Jardin de Charlotte - SAE S1.04
--  00 - Remise a zero du schema
--
--  A n'executer que pour repartir d'une base vide. Les tables sont
--  supprimees dans l'ordre inverse des dependances ; CASCADE
--  CONSTRAINTS libere les cles etrangeres qui les referencent.
--
--  Les erreurs "ORA-00942: table or view does not exist" sont normales
--  lors du premier passage.
-- =====================================================================

DROP TABLE COMPOSITION CASCADE CONSTRAINTS;
DROP TABLE BOUQUET     CASCADE CONSTRAINTS;
DROP TABLE COMMANDE    CASCADE CONSTRAINTS;
DROP TABLE ACHAT       CASCADE CONSTRAINTS;
DROP TABLE CLIENT      CASCADE CONSTRAINTS;
DROP TABLE LOCALITE    CASCADE CONSTRAINTS;
DROP TABLE GROSSISTE   CASCADE CONSTRAINTS;
DROP TABLE FLEUR       CASCADE CONSTRAINTS;

-- Tables de travail utilisees par 03_import_donnees.sql
DROP TABLE TMP_COMMANDES    CASCADE CONSTRAINTS;
DROP TABLE TMP_COMPOSITIONS CASCADE CONSTRAINTS;
DROP TABLE TMP_ACHATS       CASCADE CONSTRAINTS;
DROP TABLE TMP_FLEURS       CASCADE CONSTRAINTS;
DROP TABLE TMP_GROSSISTES   CASCADE CONSTRAINTS;
DROP TABLE TMP_LIVRAISONS   CASCADE CONSTRAINTS;
