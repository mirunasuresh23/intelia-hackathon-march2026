import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

def one_off_load():
    logging.warning("This script is DEPRECATED. Bronze tables are now External and do not require manual ingestion.")
    logging.info("Please use deploy_dwh.py to set up the infrastructure.")

if __name__ == "__main__":
    one_off_load()
