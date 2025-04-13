const {hello} = require('../services/base');

const sayHello = (req, res) => {
    const message = hello();
    res.send(message);
}

module.exports={
    sayHello,
}