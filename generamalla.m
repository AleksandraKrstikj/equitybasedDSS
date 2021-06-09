S = shaperead('shapes\Mancha_Urbana.shp');% Read the Shapefile of municipal boundaries or general area of interest. The shapefile of municipal boundary is usually available in National Geostatistics Open Databases or it can be manually digitalized/preprocessed in QGIS before incorporating it into the system
dxy=km2deg(20/1000);%Defining the 20 meters distance between houses in the municiaplity or area of interest
%definition of municipality´s limits to implement a equidistant (20 meters) grid
minX=min(S.X);
maxX=max(S.X);
minY=min(S.Y);
maxY=max(S.Y);
nX=(minX:dxy:maxX);
nY=(minY:dxy:maxY);
%%% end of the definition of municipality´s limits
[X,Y] = meshgrid(nX,nY);%creating the 20x20 meters meshgrid
vX=reshape(X,[length(nX)*length(nY) 1]);
vY=reshape(Y,[length(nX)*length(nY) 1]);
in = inpolygon(vX,vY,S.X,S.Y);% removing grid points outside the municipality´s limits
grX=vX(in);
grY=vY(in);
grZ=grY;
grZ(:)=0;
plot(S.X,S.Y)% ploting the municipality´s limits
hold on 
S1=shaperead('shapes\solo_comida.shp');% reading the georeferenced point data of location of operational shops that was previsouly digitalized in QGIS. We used Google API to digitalized locations from a list of shops with addresses provided from the municipality
S2=shaperead('shapes\voronoi_comida.shp');% reading the Voronoi tessellation of the set of points that are the shop point locations that was previously calculated in QGIS with Vector Geometry Tools-Voronoi Polygons
for i=1:numel(S2)% loop to operate over all the Voronoi areas
    in = inpolygon(grX,grY,S2(i).X,S2(i).Y);% finding meshgrid points that are inside an i Voronoi Area
    S2(i).grX=grX(in);
    S2(i).grY=grY(in);    
    [arclen,az] = distance(S2(i).grY,S2(i).grX,S1(i).Y,S1(i).X);% Calculating the distance between all meshgrid points and the i businesses
    S2(i).distKm=deg2km(arclen);
    grZ(in)=S2(i).distKm;%adding the distance to the vector grZ 
end
x=grX;y=grY;z=grZ;
Z_volunt=grY;
Z_volunt(:)=0;
SU = shaperead('shapes\AA.shp');% reading the data of neighborhoods´ boundaries or specific smaller areas of interest insidethe general area. The shapefile of neighborhood boundaries is usually available in National Geostatistics Open Databases or it can be manually digitalized/preprocessed in QGIS before incorporating it into the system
radio_atencion=8; %Defining the number of people that can be attended per day at a distance of 1 km (this can be a function), in our study case is 8 people per day attended by 1 volunteer
for i=1:numel(SU)
    in = inpolygon(x,y,SU(i).X,SU(i).Y);% finding the meshgrid points that are inside the neighborhood poligons
    adul_may=SU(i).POB_2010*(44006/489879);%calculation of the number of people inside the i neighborhood polygon that are going to be attended, in our case study are senior citizens older than 60 years
    pobcada20m=adul_may/sum(in);%calculating the number of senior citizens in each point of the meshgrid of 20 m
    adul_may_jornada=radio_atencion./z(in);% calculation of the number of senior citizens that can be atended in each grid point by calculating the ratio between the number of people that can be attended with the distance between the store and the meshgrid point
    volun_neces=pobcada20m./adul_may_jornada;% calculation of the number of volunteers that are needed to attend senior citizens in each meshgrid point 
    id_inf=find(isinf(volun_neces));% the previous result could be infinitum if there are 0 senior citizens
    if ~isempty(id_inf)
        volun_neces(id_inf)=0;% there is no need of volunteers if there are no senior citizens to be attended
    end
    SU(i).volun_neces=round(sum(volun_neces));% summation of volunteers per neighborhood polygon, or calculating the sum of needed volunteers for all meshgrid points in one neighborhood polygon
    SU(i).adul_may=adul_may;
    SU(i).Tex_adul_may=[num2str(round(sum(volun_neces))),'/',num2str(round(adul_may))];
    Z_volunt(in)=volun_neces; 
end
shapewrite(SU,'Voluntarios_necesarios.shp') %saving results
% code to plot results 
 dt = delaunayTriangulation(x,y) ;
 tri = dt.ConnectivityList ;
 xi = dt.Points(:,1) ; 
 yi = dt.Points(:,2) ; 
 F = scatteredInterpolant(x,y,Z_volunt);
 zi = F(xi,yi) ;
 trisurf(tri,xi,yi,zi) 
 view(2)
 shading interp
 hold on
 plot3(S.X,S.Y,S.Y*0+1)
 xlabel('Longitud');
 ylabel('Latitud');
 zlabel('No. Volunt.');
