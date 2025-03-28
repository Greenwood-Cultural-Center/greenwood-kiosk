module Api
  class JsonController < ApplicationController
   # "api/search?search=your_search"  provide your search as a query parameter called search like so
   #http://127.0.0.1:3000/api/search?search=#{params[:search]}&year=#{params[:year]} the year parameter should only be 1920,1910 or the word Both
   @@search_controller = SearchController.new
 
   def json
      
    
      
      @buildings =  @@search_controller.search_buildings(params["search"],params["year"])
      @ready_buildings =[]
      
      @buildings.each{|building|  @ready_buildings.append(make_building(building,params["year"])) } 
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
          {"buildings": @ready_buildings}
          
        
        ],

        
        "count":
        { 
          "buildings": @ready_buildings.count


        }
      }
      
    end

    

    private def make_building(record,year)
      
        feature = @@search_controller.make_feature(record,year)
       
      
      
     
      
      
      return feature
    end

    

  end
end