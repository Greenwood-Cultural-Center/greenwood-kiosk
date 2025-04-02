module Api
  class JsonController < ApplicationController
   # "api/search?search=your_search"  provide your search as a query parameter called search like so
   #http://127.0.0.1:3000/api/search?search=#{params[:search]}&year=#{params[:year]} the year parameter should only be 1920,1910 or the word Both
   @@search_controller = SearchController.new
 
    def json
      @buildings =  @@search_controller.search_buildings(params["search"],params["year"])
      @ready_buildings =[]
      @buildings.each{|building|  @ready_buildings.append(make_building(building,params["year"])) } 
      @ready_buildings = @ready_buildings.compact
        @people =  search_people(params["search"],params["year"])
        @ready_people =[]
        
        @people.each{|person|  @ready_people.append(make_person(person,params["year"])) } 
        @ready_people = @ready_people.compact
        @finished_json = build_json
        response.set_header('Access-Control-Allow-Origin', '*')
        render json: @finished_json

    end

    private def search_query(class_name,chosen_query)
      class_object = class_name.constantize
      table_name = class_object.table_name
      class_object.column_names.each do |name|
        
            query= "#{table_name}.#{name}::varchar ILIKE :search OR "
            chosen_query = chosen_query.concat(query) 
        
      end
      chosen_query
    end

    private def build_json
      {
        "results":
        [
          {"buildings": @ready_buildings},
          {"people": @ready_people}
        ],
        "count":
        { 
          "buildings": @ready_buildings.count,
          "people": @ready_people.count
        }
      }
    end
    def make_building(record,year)

      def get_media(record)
        media_array = []

        record.photos.each {|photo| media_array.append({"type": "photo","id": photo.id})}
        record.audios.each {|audio| media_array.append({"type": "audio","id": audio.id})}
        record.videos.each {|video| media_array.append({"type": "video","id": video.id})}
        record.narratives.each {|narrative| media_array.append({"type": "narrative","id": narrative.id})}

        return media_array
      end

      def get_censusrecord(census_array)
        json_array = []
        census_array.each {|census| json_array.append(census.id)}
        return json_array
      end
      def get_person(person)
        person_narratives = []
        person.narratives.each {|narrative| person_narratives.append({record: narrative,sources:narrative.sources,story:narrative.story})}
        person_photos = []
        person.photos.each {|photo| person_photos.append({record: photo,attatchment:photo.file_attachment,url:rails_blob_url(photo.file_attachment, only_path: true)}) }

        
        person_feature = {
        "person": person,
        "audios": person.audios,
        "narratives": person_narratives,
        "videos": person.videos,
        "photos": person_photos

        }
      end
      person_array_1910 =[]
      person_array_1920 =[]
      record.people_1910.each {|person| person_array_1910.append(get_person(person))}
      record.people_1920.each {|person| person_array_1920.append(get_person(person))}
      building_narratives = []
      record.narratives.each {|narrative| building_narratives.append({record: narrative,sources:narrative.sources,story:narrative.story})}
      building_photos = []
      
      if record.photos.empty? == false
      record.photos.each {|photo| building_photos.append({record: photo,attatchment:photo.file_attachment,url:rails_blob_url(photo.file_attachment, only_path: true)}) }
      end
      if year == '1920'
            feature = {
            "id": record.id,
            "name": record.name,
            "description": record.description,
            "address": record.primary_street_address,
            "location": record.coordinates,
            "properties": ["census_records1920": get_censusrecord(record.census1920_records),"census_records1910": [],"people1920": person_array_1920, "people1910": [],"media": get_media(record)  ],
            "rich_description": record.rich_text_description,
            "stories": building_narratives
        }
      elsif year == '1910'
        feature = {
        "id": record.id,
        "name": record.name,
        "description": record.description,
        "address": record.primary_street_address,
        "location": record.coordinates,
        "properties": ["census_records1920":[] ,"census_records1910": get_censusrecord(record.census1910_records),"people1920": [], "people1910": person_array_1910,"media": get_media(record)  ],
        "rich_description": record.rich_text_description,
        "stories": building_narratives
    }
      elsif year == 'Both'
        feature = {
        "id": record.id,
        "name": record.name,
        "description": record.description,
        "address": record.primary_street_address,
        "location": record.coordinates,
        "properties": ["census_records1920": get_censusrecord(record.census1920_records) ,"census_records1910": get_censusrecord(record.census1910_records),"people1920": person_array_1920, "people1910": person_array_1910,"media": get_media(record)  ],
        "rich_description": record.rich_text_description,
        "stories": building_narratives
    }
      end 
      if record.census1920_records.empty? && year =='1920'
        return 
     end
     if record.census1910_records.empty? && year =='1910'
      return 
   end
      return feature
    end
    def make_person(record,year)

      def get_media(record)
        media_array = []
        record.photos.each {|photo| media_array.append({"type": "photo","id": photo.id})}
        record.audios.each {|audio| media_array.append({"type": "audio","id": audio.id})}
        record.videos.each {|video| media_array.append({"type": "video","id": video.id})}
        record.narratives.each {|narrative| media_array.append({"type": "narrative","id": narrative.id})}
        return media_array
      end

      def get_censusrecord(census_array)
        json_array = []
        census_array.each {|census| json_array.append(census.id)}
        return json_array
      end
      
      person_narratives = []
      record.narratives.each {|narrative| person_narratives.append({record: narrative,sources:narrative.sources,story:narrative.story})}
      person_photos = []
      
      if record.photos.empty? == false
      record.photos.each {|photo| person_photos.append({record: photo,attatchment:photo.file_attachment,url:rails_blob_url(photo.file_attachment, only_path: true)}) }
      end
      if year == '1920'
            feature = {
            "id": record.id,
            "name": record.name,
            "description": record.description,
            "properties": ["census_records1920": get_censusrecord(record.census1920_records),"census_records1910": [],"buildings": record.buildings,"media": get_media(record)  ],
            "stories": person_narratives
        }
      elsif year == '1910'
        feature = {
        "id": record.id,
        "name": record.name,
        "description": record.description,
        "properties": ["census_records1920":[] ,"census_records1910": get_censusrecord(record.census1910_records),"buildings": record.buildings,"media": get_media(record)  ],
        "stories": person_narratives
      }
      elsif year == 'Both'
        feature = {
        "id": record.id,
        "name": record.name,
        "description": record.description,
        "properties": ["census_records1920": get_censusrecord(record.census1920_records) ,"census_records1910": get_censusrecord(record.census1910_records),"buildings": record.buildings,"media": get_media(record)  ],
        "stories": person_narratives
      }
      end 
      if record.census1920_records.empty? && year =='1920'
        return 
     end
     if record.census1910_records.empty? && year =='1910'
        return 
      end
      return feature
    end
    def search_people(search,year)
      @census_query = ''
        @building_query = ''
        @census1910_query=''
        @person_query = ''
        @audio_query = ''
        @video_query = ''
        @photo_query = ''
        @narrative_query = ''
        @rich_text_query = ''
        @address_query = ''
        @census_query = search_query('Census1920Record',@census_query)
        @census1910_query = search_query('Census1910Record',@census1910_query)
        @building_query = search_query('Building',@building_query)
        @person_query = search_query('Person',@person_query)
        @audio_query = search_query('Audio',@audio_query)
        @video_query = search_query('Video',@video_query)
        @photo_query = search_query('Photograph',@photo_query)
        @narrative_query = search_query('Narrative',@narrative_query)
        @rich_text_query = search_query('ActionText::RichText',@rich_text_query)
        @address_query = search_query('Address',@address_query)
        @building_query = @building_query.chomp("OR ")
        @census_query = @census_query.chomp("OR ")
        @census1910_query = @census1910_query.chomp("OR ")
        @person_query = @person_query.chomp("OR ")
        @audio_query = @audio_query.chomp("OR ")
        @video_query = @video_query.chomp("OR ")
        @photo_query = @photo_query.chomp("OR ")
        @narrative_query = @narrative_query.chomp("OR ")
        @rich_text_query = @rich_text_query.chomp("OR ")
        @address_query  = @address_query.chomp("OR ")

        if search.present?
          if year == 'Both'
          @people = Person.where(@person_query,:search => "%#{search}%").ids.uniq
          @people_photo = Person.joins(:photos).where("Photographs.searchable_text::varchar ILIKE :search",:search => "%#{search}%").ids.uniq
          @people_video = Person.joins(:videos).where("Videos.searchable_text::varchar ILIKE :search",:search => "%#{search}%").ids.uniq
          @people_audio = Person.joins(:audios).where("Audios.searchable_text::varchar ILIKE :search",:search => "%#{search}%").ids.uniq
          @people_narrative = Person.joins(:narratives).where(@narrative_query,:search => "%#{search}%").ids.uniq
          @people_action_text_story = Person.joins(narratives: :rich_text_story).where(@rich_text_query,:search => "%#{search}%").ids.uniq
          @people_action_text_sources = Person.joins(narratives: :rich_text_sources).where(@rich_text_query,:search => "%#{search}%").ids.uniq
          # @people_action_text_description = Person.joins(:rich_text_description).where(@rich_text_query,:search => "%#{search}%").ids.uniq
          #@people_address = Person.joins(:addresses).where(@address_query,:search => "%#{search}%").ids.uniq

          @people_census1920 = Person.joins(:census1920_records).where(@census_query,:search => "%#{search}%").ids.uniq
          @people_census1910 = Person.joins(:census1910_records).where(@census1910_query,:search => "%#{search}%").ids.uniq
          
          @people_buildings1910 = Person.joins(:buildings_1910).where(@person_query,:search => "%#{search}%").ids.uniq
          @people_buildings1920 = Person.joins(:buildings_1920).where(@person_query,:search => "%#{search}%").ids.uniq
            @people << @people_photo
          @people << @people_video
          @people << @people_audio
          @people << @people_narrative
          @people <<  @people_action_text_sources
          @people <<  @people_action_text_story
          # @people << @people_action_text_description
          # @people << @people_address

          @people << @people_census1920
          @people << @people_census1910
          @people << @people_buildings1910
          @people << @people_buildings1920
          
          @people = @people.flatten.uniq
          @people = Person.where(id: @people)
            
          elsif year == '1910'
            @people = Person.where(@person_query,:search => "%#{search}%").ids.uniq
            @people_photo = Person.joins(:photos).where("Photographs.searchable_text::varchar ILIKE :search",:search => "%#{search}%").ids.uniq
            @people_video = Person.joins(:videos).where("Videos.searchable_text::varchar ILIKE :search",:search => "%#{search}%").ids.uniq
            @people_audio = Person.joins(:audios).where("Audios.searchable_text::varchar ILIKE :search",:search => "%#{search}%").ids.uniq
            @people_narrative = Person.joins(:narratives).where(@narrative_query,:search => "%#{search}%").ids.uniq
            @people_action_text_story = Person.joins(narratives: :rich_text_story).where(@rich_text_query,:search => "%#{search}%").ids.uniq
            @people_action_text_sources = Person.joins(narratives: :rich_text_sources).where(@rich_text_query,:search => "%#{search}%").ids.uniq
          # @people_action_text_description = Person.joins(:rich_text_description).where(@rich_text_query,:search => "%#{search}%").ids.uniq
            #@people_address = Person.joins(:addresses).where(@address_query,:search => "%#{search}%").ids.uniq
  
            @people_census1910 = Person.joins(:census1910_records).where(@census1910_query,:search => "%#{search}%").ids.uniq
            @people_buildings1910 = Person.joins(:buildings_1910).where(@person_query,:search => "%#{search}%").ids.uniq
          
            @people << @people_photo
            @people << @people_video
            @people << @people_audio
            @people << @people_narrative
            @people <<  @people_action_text_sources
            @people <<  @people_action_text_story
          # @people << @people_action_text_description
          # @people << @people_address
  
            @people << @people_census1910
            @people << @people_buildings1910
  
            @people = @people.flatten.uniq
            @people = Person.where(id: @people)
          elsif year == '1920'
            @people = Person.where(@person_query,:search => "%#{search}%").ids.uniq
          @people_photo = Person.joins(:photos).where("Photographs.searchable_text::varchar ILIKE :search",:search => "%#{search}%").ids.uniq
          @people_video = Person.joins(:videos).where("Videos.searchable_text::varchar ILIKE :search",:search => "%#{search}%").ids.uniq
          @people_audio = Person.joins(:audios).where("Audios.searchable_text::varchar ILIKE :search",:search => "%#{search}%").ids.uniq
          @people_narrative = Person.joins(:narratives).where(@narrative_query,:search => "%#{search}%").ids.uniq
          @people_action_text_story = Person.joins(narratives: :rich_text_story).where(@rich_text_query,:search => "%#{search}%").ids.uniq
          @people_action_text_sources = Person.joins(narratives: :rich_text_sources).where(@rich_text_query,:search => "%#{search}%").ids.uniq
          # @people_action_text_description = Person.joins(:rich_text_description).where(@rich_text_query,:search => "%#{search}%").ids.uniq
          #@people_address = Person.joins(:addresses).where(@address_query,:search => "%#{search}%").ids.uniq

          @people_census1920 = Person.joins(:census1920_records).where(@census_query,:search => "%#{search}%").ids.uniq
          @people_buildings1920 = Person.joins(:buildings_1920).where(@person_query,:search => "%#{search}%").ids.uniq

            @people << @people_photo
          @people << @people_video
          @people << @people_audio
          @people << @people_narrative
          @people <<  @people_action_text_sources
          @people <<  @people_action_text_story
          # @people << @people_action_text_description
          # @people << @people_address

          @people << @people_census1920
          @people << @people_buildings1920

          @people = @people.flatten.uniq
          @people = Person.where(id: @people)
          end
        else
          @buildings = Building.all
        end
    end
    
  end
end