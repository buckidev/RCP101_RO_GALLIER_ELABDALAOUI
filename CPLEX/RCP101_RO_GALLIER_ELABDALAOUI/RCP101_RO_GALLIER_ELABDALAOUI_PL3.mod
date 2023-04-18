/*********************************************
 * OPL 12.10.0.0 Model
 * Author: benja
 * Creation Date: 24 mars 2023 at 10:36:17
 *********************************************/
int NombreEquipes = 9;
int NombreJournees = 18;
int Milieu = 9;
float EmpreinteCarbone = 1.8;

range rangeJournees = 1..NombreJournees; 
range rangeJourneesAller = 1..NombreEquipes;  
range rangeJourneesRetour = (Milieu + 1)..NombreJournees; 
range rangeEquipes = 1..NombreEquipes; 
range rangeJourneesDecales = 2..NombreJournees;


dvar boolean match[rangeJournees][rangeEquipes][rangeEquipes];
dvar boolean repos[rangeJournees][rangeEquipes];
dvar boolean recep[rangeJournees][rangeEquipes];
dvar boolean exter[rangeJournees][rangeEquipes];
dvar boolean idemRecep[rangeJournees][rangeEquipes];
dvar boolean idemExter[rangeJournees][rangeEquipes];

dvar int distanceJournees[rangeJournees];
dvar int distanceTotale;
dvar float empreinteCarboneTotale;

string NomsEquipes[rangeEquipes] = ["Aix", "Marseille", "Montpellier", "Nice", "Noisy", "Reims", "Sete", "Strasbourg", "Tourcoing"];
int Distance[rangeEquipes][rangeEquipes] = [
[0	,	33,		152,	176,	764,	780,	183,	778,	996],
[33 ,	0,		171,	203,	786,	799,	202,	797,	1015],
[152,	171,	0,		326,	755,	785,	32,		783,	975],
[176,	203,	326,	0,		940,	954,	357,	787,	1170],
[764,	786,	755,	940,	0,		140,	781,	487,	222],
[780,	799,	785,	954,	140,	0,		816,	349,	211],
[183,	202,	32,		357,	781,	816,	0,		819,	1032],
[778,	797,	783,	787,	487,	349,	819,	0,		565],
[996,	1015,	975,	1170,	222,	211,	1032,	565,	0]
];


dvar float Resultat;

minimize Resultat;

subject to  {
  
 forall(i in rangeEquipes, j in rangeEquipes : j != i){
   //Chaque équipe reçoit une fois l’autre équipe
   //L’équipe #i et l’équipe #j se rencontrent au même numéro de journée des matches Aller et Retour (une fois à domicile et l’autre à l’extérieur)
   sum(t in rangeJourneesAller) (match[t][i][j] + match[t][j][i]) == 1;
   sum(t in rangeJourneesRetour) (match[t][i][j] + match[t][j][i]) == 1;
 }

 forall(i in rangeEquipes){
   //Chaque équipe se repose une fois pendant les matchs allers et une fois pendant les retour
   sum(t in rangeJourneesAller) repos[t][i] == 1;
   sum(t in rangeJourneesRetour) repos[t][i] == 1;
   forall(j in rangeEquipes : i != j) {
	  sum(t in rangeJournees) match[t][i][j] == 1;
   } 
 }
 
  forall(t in rangeJournees){
   //Une équipe se repose à chaque journée
   sum(i in rangeEquipes) repos[t][i] == 1;
  
   forall(i in rangeEquipes){
     //Pour chaque journée, une équipe peut soit se reposer, soit recevoir ou soit être à lextérieur
     repos[t][i] + recep[t][i] + exter[t][i] == 1;
   }
   
   forall(i in rangeEquipes){
     //Lien entre la variable recep[t][i] et match[t][i][j]
     sum(j in rangeEquipes) match[t][i][j] == recep[t][i] ;
     //Lien entre la variable exter[t][i] et match[t][i][j]
     sum(j in rangeEquipes) match[t][j][i] == exter[t][i] ;
   }  
 }
 
 forall(t in rangeJourneesDecales, i in rangeEquipes) {
    //Pour chaque équipe et chaque journée >= 2 : idemRecep[t][i] vaut 1 si recep[t][i]==1 et recep[t-1][i]==1.
	idemRecep[t][i] == (recep[t][i] == 1 && recep[t-1][i] == 1);	
	//Pour chaque équipe et chaque journée >= 2 : idemExter[k][i] vaut 1 si exter[k][i]==1 et exter[k-1][i]==1.
	idemExter[t][i] == (exter[t][i]==1 && exter[t-1][i]==1);
 }
 

 
 forall(t in rangeJourneesAller,i in rangeEquipes,j in rangeEquipes){
   match[t][i][j] == match[t + Milieu][j][i];
 } 
 
 forall(t in rangeJournees) {
  //TODO  Ils retournent chez eux à chaque fois : donc compter un Aller-retour
  distanceJournees[t] == sum(i in rangeEquipes, j in rangeEquipes : i != j) (match[t][i][j] * Distance[i][j] * 2);
}
    
 distanceTotale == sum(t in rangeJournees) distanceJournees[t];
    
 empreinteCarboneTotale == EmpreinteCarbone * distanceTotale;
 
 Resultat == sum(t in rangeJournees, i in rangeEquipes)(idemExter[t][i] + idemRecep[t][i]);
}

 execute {
   for(var t = 1; t <= NombreJournees; t++){
     write("\n Journée #" + t);
     for(var i = 1; i <= NombreEquipes; i++){       
       for(var j = 1; j <= NombreEquipes; j++){
         if(match[t][i][j] == 1){
           write("    " + NomsEquipes[i] + " vs " + NomsEquipes[j]);
         }
       }            
     }
     for(var i = 1; i <= NombreEquipes; i++){  
       if(repos[t][i] == 1){
         write("    Repos pour : " + NomsEquipes[i]);
       }  
     }
     write(" = " + distanceJournees[t] + " km");     
   }
   write("\n Total Distance = " + distanceTotale + " km");     
   write("\n Total CO2 = " + empreinteCarboneTotale + " kgCO2");    
 }
