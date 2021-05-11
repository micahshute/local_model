RSpec.describe LocalModel::CSV do

    before (:all) do 
        LocalModel.config do |c|
            c.path = "./"
        end
        class User < LocalModel::CSV

            schema do |t|
                t.string :name
                t.integer :age
            end

            has_many :dogs
        end

        class Dog < LocalModel::CSV

            schema do |t|
                t.string :name
                t.integer :user_id
                t.integer :age
            end

            belongs_to :user
            has_many :dog_toys
            has_many :toys, through: :dog_toys
            has_one :collar
        end

        class Toy < LocalModel::CSV
            schema do |t|
                t.string :name
            end

            has_many :dog_toys
            has_many :dogs, through: :dog_toys
        end

        class DogToy < LocalModel::CSV
            schema do |t|
                t.integer :dog_id
                t.integer :toy_id
            end

            belongs_to :dog
            belongs_to :toy
        end

        class Collar < LocalModel::CSV
            schema do |t|
                t.string :color
                t.integer :dog_id
            end
            belongs_to :dog
        end
    end

    before :each do 
        Dog.destroy_all
        User.destroy_all
        Toy.destroy_all
        DogToy.destroy_all
    end

    after(:all) do 
        Dir.foreach('./') do |f|
            fn = File.join('./', f)
            File.delete(fn) if f.end_with?('.csv')
        end
    end


    describe "generator" do 
        it "create appropriate CSV files" do 
            expect(File.file?('./User.csv')).to be true
            expect(File.file?('./Dog.csv')).to be true
        end
    end

    describe ".create" do 
        let(:user1) { User.create(name: "A Person", age: 24) }
        it "creates an object and persists it" do 
            expect(user1.name).to eq "A Person"
            expect(user1.id).not_to be nil
            expect(user1.age).to eq 24
            expect(User.first.id).to eq user1.id
        end
    end

    describe ".new" do
        let(:user2) { User.new(name: "Peter Blood", age: 35) }

        it "does not persist a User on .new call" do
            expect(user2.name).to eq "Peter Blood"
            expect(user2.id).to be nil
            expect(User.first&.name).not_to eq user2.name
        end
    end


    describe ".find" do 
        before { 20.times{ |i| User.create(name: "Person #{i}") } }

        it "finds the appropriate user object" do 
            u = User.find(17)
            expect(u.id).to eq 17
        end
    end

    describe ".where" do 
        let!(:shaggy) do 
            User.create(name: "Shaggy", age: 23)
        end

        let!(:scooby) do 
            Dog.create(name: "Scooby", age: 4, user: shaggy)
        end

        let!(:scrappy) do 
            Dog.create(name: "Scrappy", age: 1, user: shaggy)
        end

        it "finds an object according to the inputted params" do
            dogs = Dog.where(user_id: shaggy.id)
            expect(dogs.length).to eq(2)
        end
    end

    describe "relationships" do 
        let!(:roger) do 
            User.create(name: "Roger", age: 38)
        end

        let!(:pongo) do
            Dog.create(name: "Pongo", age: 5, user: roger)
        end

        let!(:perdita) do 
            Dog.create(name: "Perdita", age: 4, user: roger)
        end

        let!(:bone) do 
            Toy.create(name: "bone")
        end

        let!(:pongos_collar) do 
            Collar.create(color: "blue", dog: pongo)
        end

        let!(:dog_bones) do 
            toy = Toy.first
            pongo_bone = DogToy.create(dog: pongo, toy: toy)
            perdita_bone = DogToy.create(dog: perdita, toy: toy)
        end

        it "can manage has_many relationships" do
            expect(roger.dogs.length).to eq 2
            expect(perdita.user.id).to eq roger.id
        end

        it "can manage has_many through relationships" do
            expect(pongo.toys.length).to eq 1
            expect(perdita.toys.first.name).to eq "bone"
            expect(pongo.dog_toys.length).to eq 1
            expect(Toy.first.dogs.length).to eq 2
        end

        it "can manage has_one relationship" do 
            expect(pongo.collar.color).to eq ("blue")
            expect(Collar.first.dog.name).to eq("Pongo")
        end
    end
end