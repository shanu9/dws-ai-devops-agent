"""
Initialize Database
Creates all tables and seeds initial data

Run: python init_db.py
"""
import sys
from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import sessionmaker
from database import Base, engine, SessionLocal
from models.customer import Customer
from models.deployment import Deployment
from models.user import User

def check_tables_exist():
    """Check if tables already exist"""
    inspector = inspect(engine)
    existing_tables = inspector.get_table_names()
    return existing_tables

def create_tables():
    """Create all tables"""
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("✅ Tables created successfully!")

def seed_data():
    """Seed initial test data"""
    db = SessionLocal()
    
    try:
        # Check if data already exists
        existing_customers = db.query(Customer).count()
        if existing_customers > 0:
            print(f"⚠️  Database already has {existing_customers} customers. Skipping seed data.")
            return
        
        print("\nSeeding test data...")
        
        # Create test customer
        test_customer = Customer(
            customer_id="demo01",
            customer_name="Demo Customer",
            email="demo@example.com",
            package_tier="standard",
            monthly_cost=3500.0,
            region="eastus",
            region_code="eus",
            hub_vnet_cidr="10.1.0.0/16",
            spoke_vnet_cidr="10.2.0.0/16",
            status="active",
            is_deployed=False
        )
        db.add(test_customer)
        
        # Create admin user
        admin_user = User(
            username="admin",
            email="admin@example.com",
            hashed_password="$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqNlYqJ7MK",  # "admin123"
            role="admin",
            is_active=True
        )
        db.add(admin_user)
        
        db.commit()
        print("✅ Seed data created successfully!")
        print("\nTest credentials:")
        print("  Username: admin")
        print("  Password: admin123")
        
    except Exception as e:
        print(f"❌ Error seeding data: {e}")
        db.rollback()
    finally:
        db.close()

def display_summary():
    """Display database summary"""
    db = SessionLocal()
    
    try:
        customer_count = db.query(Customer).count()
        deployment_count = db.query(Deployment).count()
        user_count = db.query(User).count()
        
        print("\n" + "="*50)
        print("DATABASE SUMMARY")
        print("="*50)
        print(f"📊 Customers:   {customer_count}")
        print(f"🚀 Deployments: {deployment_count}")
        print(f"👤 Users:       {user_count}")
        print("="*50)
        
        # List customers
        if customer_count > 0:
            print("\nCustomers:")
            customers = db.query(Customer).all()
            for customer in customers:
                print(f"  - {customer.customer_id}: {customer.customer_name} ({customer.package_tier})")
        
    finally:
        db.close()

def main():
    """Main initialization function"""
    print("="*50)
    print("AZURE CAF-LZ DATABASE INITIALIZATION")
    print("="*50)
    
    # Check existing tables
    existing_tables = check_tables_exist()
    if existing_tables:
        print(f"\n⚠️  Found existing tables: {', '.join(existing_tables)}")
        response = input("Recreate tables? This will DELETE ALL DATA! (yes/no): ")
        if response.lower() != "yes":
            print("Initialization cancelled.")
            sys.exit(0)
        
        print("\n🗑️  Dropping existing tables...")
        Base.metadata.drop_all(bind=engine)
        print("✅ Tables dropped.")
    
    # Create tables
    create_tables()
    
    # Seed data
    seed_data()
    
    # Display summary
    display_summary()
    
    print("\n✅ Database initialization complete!")
    print("\nNext steps:")
    print("  1. Start backend: python main.py")
    print("  2. Start frontend: npm run dev")
    print("  3. Open http://localhost:3000")

if __name__ == "__main__":
    main()