( function _Cui_s_( )
{

'use strict';

//

let _ = _global_.wTools;
let Parent = null;
let Self = wFilerCui;
function wFilerCui( o )
{
  return _.workpiece.construct( Self, this, arguments );
}

Self.shortName = 'Cui';

// --
// inter
// --

function init( o )
{
  let cui = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  _.workpiece.initFields( cui );
  Object.preventExtensions( cui );

  if( o )
  cui.copy( o );

}

//

function Exec()
{
  let cui = new this.Self();
  return cui.exec();
}

//

function exec()
{
  let cui = this;

  _.assert( arguments.length === 0 );

  let appArgs = _.process.args();
  let ca = cui._commandsMake();

  return _.Consequence
  .Try( () =>
  {
    return ca.appArgsPerform({ appArgs });
  })
  .catch( ( err ) =>
  {
    _.process.exitCode( -1 );
    logger.log( _.errOnce( err ) );
    _.procedure.terminationBegin();
    _.process.exit();
    return err;
  });
}

// --
// commands
// --

function _commandsMake()
{
  let cui = this;
  let appArgs = _.process.args();

  _.assert( _.instanceIs( cui ) );
  _.assert( arguments.length === 0 );

  let commands =
  {
    'help' :              { e : _.routineJoin( cui, cui.commandHelp )          },
    'version' :           { e : _.routineJoin( cui, cui.commandVersion )       },
    'imply' :             { e : _.routineJoin( cui, cui.commandImply )         },
    'storage reset' :     { e : _.routineJoin( cui, cui.commandStorageReset )  },
    'storage print' :     { e : _.routineJoin( cui, cui.commandStoragePrint )  },
    'status' :            { e : _.routineJoin( cui, cui.commandStatus )        },
    'replace' :           { e : _.routineJoin( cui, cui.commandReplace )       },
    'do' :                { e : _.routineJoin( cui, cui.commandDo )            },
    'redo' :              { e : _.routineJoin( cui, cui.commandRedo )          },
    'undo' :              { e : _.routineJoin( cui, cui.commandUndo )          },
  }

  let ca = _.CommandsAggregator
  ({
    basePath : _.path.current(),
    commands,
    commandPrefix : 'node ',
  })

  ca.form();

  return ca;
}

//

function _command_pre( routine, args )
{

  _.assert( arguments.length === 2 );
  _.assert( args.length === 1 );

  let e = args[ 0 ];

  _.assert( _.mapIs( e.propertiesMap ), () => 'Expects map, but got ' + _.toStrShort( e.propertiesMap ) );
  _.assertMapHasOnly( e.propertiesMap, routine.commandProperties, `Command does not expect options:` );

  if( routine.commandProperties.v )
  if( e.propertiesMap.v !== undefined )
  {
    e.propertiesMap.verbosity = e.propertiesMap.v;
    delete e.propertiesMap.v;
  }

  return e;
}

//

function commandHelp( e )
{
  let cui = this;
  let ca = e.ca;

  ca._commandHelp( e );

  return cui;
}

commandHelp.hint = 'Get help.';

//

function commandVersion( e ) /* xxx qqq : move to NpmTools */
{
  let cui = this;
  let packageJsonPath = path.join( __dirname, '../../../../../package.json' );
  let packageJson =  _.fileProvider.fileRead({ filePath : packageJsonPath, encoding : 'json', throwing : 0 });

  return _.process.start
  ({
    execPath : 'npm view wfiler@latest version',
    outputCollecting : 1,
    outputPiping : 0,
    inputMirroring : 0,
    throwingExitCode : 0,
  })
  .then( ( got ) =>
  {
    let current = packageJson ? packageJson.version : 'unknown';
    let latest = _.strStrip( got.output );

    if( got.exitCode || !latest )
    latest = 'unknown'

    logger.log( 'Current version:', current );
    logger.log( 'Available version:', latest );

    return null;
  })

}

commandVersion.hint = 'Get information about version.';

//

function commandImply( e )
{
  let cui = this;
  let ca = e.ca;
  let isolated = ca.commandIsolateSecondFromArgument( e.argument );

  _.assert( !!isolated );
  _.assert( 0, 'not tested' );

  let request = _.strRequestParse( isolated.argument );

  let namesMap =
  {
    v : 'verbosity',
    verbosity : 'verbosity',
  }

  if( request.map.v !== undefined )
  {
    request.map.verbosity = request.map.v;
    delete request.map.v;
  }

  _.process.argsReadTo
  ({
    dst : implied,
    propertiesMap : request.map,
    namesMap,
  });

}

commandImply.hint = 'Change state or imply value of a variable.';
commandImply.commandProperties =
{
  verbosity : 'Level of verbosity.',
  v : 'Level of verbosity.',
}

//

function commandStorageReset( e )
{
  let cui = this;
  let ca = e.ca;

  cui._command_pre( commandStorageReset, arguments );
  _.censor.storageReset( e.propertiesMap );

}

commandStorageReset.hint = 'Delete current state forgetting everything.';
commandStorageReset.commandProperties =
{
  verbosity : 'Level of verbosity.',
  v : 'Level of verbosity.',
}

//

function commandStoragePrint( e )
{
  let cui = this;
  let ca = e.ca;

  cui._command_pre( commandStoragePrint, arguments );
  let read = _.censor.storageRead( e.propertiesMap );

  logger.log( read );

}

commandStoragePrint.hint = 'Print content of storage file.';
commandStoragePrint.commandProperties =
{
}

//

function commandStatus( e )
{
  let cui = this;
  let ca = e.ca;

  cui._command_pre( commandStatus, arguments );

  let status = _.censor.status( e.propertiesMap );

  logger.log( _.toStrNice( status ) );

}

commandStatus.hint = 'Get status of the current state.';
commandStatus.commandProperties =
{
  verbosity : 'Level of verbosity. Default = 3',
  v : 'Level of verbosity. Default = 3',
}

//

function commandReplace( e )
{
  let cui = this;
  let ca = e.ca;
  let op = e.propertiesMap;

  cui._command_pre( commandReplace, arguments );
  op.logging = 1;

  return _.censor.filesReplace( op );
}

commandReplace.hint = 'Replace text in files.';
commandReplace.commandProperties =
{
  verbosity : 'Level of verbosity. Default = 3',
  v : 'Level of verbosity. Default = 3',
  basePath : 'Base path of directory to look. Default = current path.',
  filePath : 'File path or glob to files to edit.',
  ins : 'Text to find in files to replace by {- sub -}.',
  sub : 'Text to put instead of ins.',
}

//

function commandDo( e )
{
  let cui = this;
  let ca = e.ca;
  let op = e.propertiesMap;

  cui._command_pre( commandDo, arguments );
  op.logging = 1;

  if( op.d !== undefined )
  {
    op.depth = op.d;
    delete op.d;
  }

  return _.censor.do( op );
}

commandDo.hint = 'Do actions planned earlier. Alias of command redo.';
commandDo.commandProperties =
{
  verbosity : 'Level of verbosity. Default = 3',
  v : 'Level of verbosity. Default = 3',
  depth : 'How many action to do. Zero for no limit. Default = 0.',
  d : 'How many action to do. Zero for no limit. Default = 0.',
}

//

function commandRedo( e )
{
  let cui = this;
  let ca = e.ca;
  let op = e.propertiesMap;

  cui._command_pre( commandRedo, arguments );
  op.logging = 1;

  if( op.d !== undefined )
  {
    op.depth = op.d;
    delete op.d;
  }

  return _.censor.redo( op );
}

commandRedo.hint = 'Do actions planned earlier. Alias of command do.';
commandRedo.commandProperties =
{
  verbosity : 'Level of verbosity. Default = 3',
  v : 'Level of verbosity. Default = 3',
  depth : 'How many action to redo. Zero for no limit. Default = 0.',
  d : 'How many action to do. Zero for no limit. Default = 0.',
}

//

function commandUndo( e )
{
  let cui = this;
  let ca = e.ca;
  let op = e.propertiesMap;

  cui._command_pre( commandUndo, arguments );
  op.logging = 1;

  if( op.d !== undefined )
  {
    op.depth = op.d;
    delete op.d;
  }

  if( op.verbosity === undefined )
  op.verbosity = 3;

  return _.censor.undo( op );
}

commandUndo.hint = 'Undo an action done earlier.';
commandUndo.commandProperties =
{
  verbosity : 'Level of verbosity. Default = 3',
  v : 'Level of verbosity. Default = 3',
  depth : 'How many action to undo. Zero for no limit. Default = 0.',
  d : 'How many action to undo. Zero for no limit. Default = 0.',
}

// --
// relations
// --

let Composes =
{
}

let Aggregates =
{
}

let Associates =
{
}

let Restricts =
{
  implied : _.define.own( {} ),
}

let Statics =
{
  Exec,
}

let Forbids =
{
}

// --
// declare
// --

let Extend =
{

  // inter

  init,
  Exec,
  exec,

  // commands

  _commandsMake,
  _command_pre,

  commandHelp,
  commandVersion,
  commandImply,
  commandStorageReset,
  commandStoragePrint,
  commandStatus,
  commandReplace,

  commandDo,
  commandRedo,
  commandUndo,

  // relations

  Composes,
  Aggregates,
  Associates,
  Restricts,
  Statics,
  Forbids,

}

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Extend,
});

_.Copyable.mixin( Self );

//

if( typeof module !== 'undefined' )
module[ 'exports' ] = Self;
_.filer[ Self.shortName ] = Self;
if( !module.parent )
Self.Exec();

})();
