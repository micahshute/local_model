
RSpec.describe LocalModel::CSV do

    before (:all) do 
        LocalModel.config do |c|
            c.path = "./"
            c.namespace = "InMemory"
        end
        module InMemory; end
        class InMemory::User < LocalModel::CSV

            schema do |t|
                t.string :name
                t.integer :age
            end

            has_many :dogs
        end

        class InMemory::Dog < LocalModel::CSV

            schema do |t|
                t.string :name
                t.integer :user_id
                t.integer :age
                t.integer :friend_id
            end

            belongs_to :user
            has_many :dog_toys
            has_many :toys, through: :dog_toys
            has_one :collar
            belongs_to :bestie, foreign_key: :friend_id, class_name: :Dog
            has_many :dog_followers, foreign_key: :following_id, class_name: :DogFollower
            has_many :dog_followings, foreign_key: :follower_id, class_name: :DogFollower
            has_many :followers, through: :dog_followers, foreign_key: :follower_id, class_name: :Dog
            has_many :followings, through: :dog_followings, foreign_key: :following_id, class_name: :Dog

        end

        class InMemory::DogFollower < LocalModel::CSV
            schema do |t|
                t.integer :following_id
                t.integer :follower_id
            end

            belongs_to :follower, foreign_key: :follower_id, class_name: :Dog
            belongs_to :following, foreign_key: :following_id, class_name: :Dog
        end

        class InMemory::Toy < LocalModel::CSV
            schema do |t|
                t.string :name
            end

            has_many :dog_toys
            has_many :dogs, through: :dog_toys
        end

        class InMemory::DogToy < LocalModel::CSV
            schema do |t|
                t.integer :dog_id
                t.integer :toy_id
            end

            belongs_to :dog
            belongs_to :toy
        end

        class InMemory::Collar < LocalModel::CSV
            schema do |t|
                t.string :color
                t.integer :dog_id
            end
            belongs_to :dog
        end
    end

    before :each do 
        InMemory::Dog.destroy_all
        InMemory::User.destroy_all
        InMemory::Toy.destroy_all
        InMemory::DogToy.destroy_all
        InMemory::Collar.destroy_all
        InMemory::DogFollower.destroy_all
    end

    after(:all) do 
        Dir.foreach('./') do |f|
            fn = File.join('./', f)
            File.delete(fn) if f.end_with?('.csv')
        end
    end


    describe "generator" do 
        it "create appropriate CSV files" do 
            expect(File.file?('./InMemory::User.csv')).to be true
            expect(File.file?('./InMemory::Dog.csv')).to be true
        end
    end

    describe ".create" do 
        let(:user1) { InMemory::User.create(name: "A Person", age: 24) }
        it "creates an object and persists it" do 
            expect(user1.name).to eq "A Person"
            expect(user1.id).not_to be nil
            expect(user1.age).to eq 24
            expect(InMemory::User.first.id).to eq user1.id
        end
    end

    describe ".new" do
        let(:user2) { InMemory::User.new(name: "Peter Blood", age: 35) }

        it "does not persist a User on .new call" do
            expect(user2.name).to eq "Peter Blood"
            expect(user2.id).to be nil
            expect(InMemory::User.first&.name).not_to eq user2.name
        end
    end


    describe ".find" do 
        before { 20.times{ |i| InMemory::User.create(name: "Person #{i}") } }

        it "finds the appropriate user object" do 
            u = InMemory::User.find(17)
            expect(u.id).to eq 17
        end
    end

    describe ".where" do 
        let!(:shaggy) do 
            InMemory::User.create(name: "Shaggy", age: 23)
        end

        let!(:scooby) do 
            InMemory::Dog.create(name: "Scooby", age: 4, user: shaggy)
        end

        let!(:scrappy) do 
            InMemory::Dog.create(name: "Scrappy", age: 1, user: shaggy)
        end

        it "finds an object according to the inputted params" do
            dogs = InMemory::Dog.where(user_id: shaggy.id)
            expect(dogs.length).to eq(2)
        end
    end

    describe "edge cases" do 
        let(:griffin){ InMemory::Dog.create }

        it "can accept nil as a belongs_to ref" do 
            expect do 
                griffin.user = nil
                griffin.save
            end.to_not raise_error
        end
    end

    describe "relationships" do 
        let!(:roger) do 
            InMemory::User.create(name: "Roger", age: 38)
        end

        let!(:pongo) do
            InMemory::Dog.create(name: "Pongo", age: 5, user: roger)
        end

        let!(:perdita) do 
            InMemory::Dog.create(name: "Perdita", age: 4, user: roger)
        end

        let!(:bone) do 
            InMemory::Toy.create(name: "bone")
        end

        let!(:pongos_collar) do 
            InMemory::Collar.create(color: "blue", dog: pongo)
        end

        let!(:dog_bones) do 
            toy = InMemory::Toy.first
            pongo_bone = InMemory::DogToy.create(dog: pongo, toy: toy)
            perdita_bone = InMemory::DogToy.create(dog: perdita, toy: toy)
        end

        let!(:puppy) do 
            InMemory::Dog.create(name: "Puppy", age: 0)
        end

        let!(:following) do 
            InMemory::DogFollower.create(following: pongo, follower: perdita)
        end

        it "can manage has_many relationships" do
            expect(roger.dogs.length).to eq 2
            expect(perdita.user.id).to eq roger.id
            roger.dogs << puppy
            expect(roger.dogs.length).to eq 3
        end

        it "can manage has_many through relationships" do
            expect(pongo.toys.length).to eq 1
            expect(perdita.toys.first.name).to eq "bone"
            expect(pongo.dog_toys.length).to eq 1
            expect(InMemory::Toy.first.dogs.length).to eq 2
        end

        it "can manage has_one relationship" do 
            expect(pongo.collar.color).to eq ("blue")
            expect(InMemory::Collar.first.dog.name).to eq("Pongo")
        end

        it "can do foreign_key and class_name in belongs_to" do 
            pongo.bestie = perdita
            pongo.save
            test_pongo = InMemory::Dog.find_by(name: 'Pongo')
            expect(test_pongo.bestie.id).to eq(perdita.id)
        end

        it "can do complex many to many" do 
            pongo_followers = pongo.followers
            pongo_followings = pongo.followings
            perdita_followers = perdita.followers
            perdita_followings = perdita.followings
            expect(pongo_followers.length).to eq 1
            expect(pongo_followers.first.name).to eq 'Perdita'
            expect(pongo_followings.length).to eq 0
            expect(perdita_followers.length).to eq 0
            expect(perdita.followings.length).to eq 1
            expect(perdita.followings.first.name).to eq 'Pongo'
            perdita_followers << pongo
            expect(perdita_followers.length).to eq 1
            expect(perdita.followers.first.name).to eq 'Pongo'
        end
    end
end