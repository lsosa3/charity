// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;

// ALUMNO   |   ID     |   NOTAS
// Marcos   |   1234   |   int96


contract grades {
    
    // Teacher's address
    address public teacher;
    
    // constructor
    constructor () public {
        teacher = msg.sender;
    }
    
    // Mapping to bind student id with grade
    mapping (bytes32 => uint) Notas;
    
    //Array de los alumnos que soliciten revisiones de examen
    string [] revisiones;
    
    // Eventos
    event alumno_evaluado(bytes32);
    event evento_revision(string);
    
    function Evaluar(string memory _idAlumno, uint _nota) public UnicamenteProfesor(msg.sender) {
        // Hash de la identificacion del alumno_evaluado
        bytes32 hash_idAlumno = keccak256(abi.encodePacked(_idAlumno));
        
        // Relacion entre el hash del Id del alumno y su Notas
        Notas[hash_idAlumno] = _nota;
        
        // Emision del evento_revision
        emit alumno_evaluado(hash_idAlumno);
    }
    
    modifier UnicamenteProfesor(address _direccion) {
        // Requiere que la direccion en el parametro sea igual al owner del contrato
        require(_direccion == teacher, "Solo puede ejecutar el profesor");
        _;
    }
    
    // Funcion para ver las notas del alumno_evaluado
    function VerNotas(string memory _idAlumno) public view returns(uint) {
        bytes32 hash_idAlumno = keccak256(abi.encodePacked(_idAlumno));
        
        // Nota asiciada al alumno
        uint nota_alumno = Notas[hash_idAlumno];
        
        return nota_alumno;
    }
    
    // Funcion para pedir una revision del examen
    function Revision(string memory _idAlumno) public {
        // Almacenamiento de la identidad del alumno en un Array
        revisiones.push(_idAlumno);
        
        //Emision del evento_revision
        emit evento_revision(_idAlumno);
    }
    
    // Funcion para ver los alumnos que han solicitado revision de examen
    function VerRevisiones() public view UnicamenteProfesor(msg.sender) returns (string [] memory) {
        // devolver las identidades de los alumnos que pidieron revision    
        return revisiones;
    }
}
