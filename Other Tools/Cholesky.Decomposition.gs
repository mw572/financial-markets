function cholesky(matrixrange) {

  //input matrix range in "a1:b2" format
  //matrix = [[1,2,3],[4,5,6],[7,8,9]]; //for testing
  
  ss = SpreadsheetApp.getActiveSheet();
  
  matrix = matrixrange;//get our data
  cols = matrix.length; //get its size

  temp1 = [];temp2 = [];lower = [];a = []; //creating our matrix frames
  
  i=0;j=0;k=0;
  
  for(var i=0;i<cols;i++){ //row iterations
    
    for(var j=0;j<cols;j++){ //col iterations
    
      temp1.push(matrix[i][j]); //filling with input elements
      temp2.push(0); //filling with zeros
    
    }
    a.push(temp1); //filling 'a' matrix with temp 1
    lower.push(temp2); //filling lower matrix with temp 2
    temp1 = [];temp2 = []; //reset for next iteration
  }
  
  for(var i=0;i<cols;i++){
    
    for(var j=0;j<cols;j++){
      
      element = a[i][j]; //getting our term
      
      for(var k=0;k<i-1;k++){ //matrix numeracy using k term
        
        element = element - lower[i][k] * lower[j][k];
        
      }
      
      if(i==j){
        lower[i][i] = Math.sqrt(element);
      }
      if(i<j){
        lower[j][i] = element / lower[i][i];
      }
    }
  }
   
  return lower; //returning a lower triangular matrix of same dimension
  
}
