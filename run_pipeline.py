import subprocess
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

def run_script(script_name):
    logging.info(f"Running {script_name}...")
    result = subprocess.run(["python", script_name], capture_output=True, text=True)
    if result.returncode == 0:
        logging.info(f"Successfully completed {script_name}.\n{result.stdout}")
    else:
        logging.error(f"Error running {script_name}:\n{result.stderr}")
        return False
    return True

def main():
    # 1. Setup Infrastructure
    if not run_script("deploy_dwh.py"): return

    # 2. Ingest Data (One-off)
    if not run_script("ingest_one_off.py"): return

    # 3. Apply Governance
    if not run_script("apply_governance.py"): return

    logging.info("========================================")
    logging.info("PIPELINE AUTOMATION COMPLETE")
    logging.info("========================================")
    logging.info("NEXT STEPS FOR GENAI (Manual Setup required for Connection):")
    logging.info("1. Run the 'bq mk --connection' command from genai_queries.sql in your CLI.")
    logging.info("2. Execute the SQL within transform_to_silver.sql and genai_queries.sql in the BigQuery Console.")

if __name__ == "__main__":
    main()
